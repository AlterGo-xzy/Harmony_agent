[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MainHap,

    [Parameter(Mandatory = $true)]
    [string]$TestHap,

    [string]$HdcPath = 'D:\DevEco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',

    [ValidateRange(1, 65535)]
    [int]$DevicePort = 4010,

    [string]$BundleName = 'com.harmony.agent',

    [switch]$PreserveExistingMain,

    [switch]$AllowDeviceChanges
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $AllowDeviceChanges) {
    throw 'Device installation, reverse forwarding, test execution, and uninstall require -AllowDeviceChanges.'
}

$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDirectory = Join-Path $workspaceRoot "artifacts\t28-local-ai-gateway-device\$timestamp"
$logsDirectory = Join-Path $runDirectory 'logs'
New-Item -ItemType Directory -Path $logsDirectory -Force | Out-Null

function Resolve-WorkspaceFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($workspaceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'HAP inputs must stay inside the Harmony Agent workspace.'
    }
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "HAP input is not a file: $resolved"
    }
    return $resolved
}

function Invoke-HdcLogged {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$LogName,
        [switch]$AllowFailure
    )
    $output = & $script:Hdc @Arguments 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    [IO.File]::WriteAllText((Join-Path $logsDirectory $LogName), $output, [Text.UTF8Encoding]::new($false))
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "hdc failed with exit code $exitCode. See $LogName"
    }
    return $output
}

function Assert-InstallSucceeded {
    param([string]$Output, [string]$Kind)
    if ($Output -notmatch '(?i)install bundle successfully') {
        throw "$Kind HAP installation did not report success."
    }
}

$gatewayBaseUrl = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_BASE_URL', 'Process')
$gatewayToken = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', 'Process')
if ([string]::IsNullOrWhiteSpace($gatewayBaseUrl) -or [string]::IsNullOrWhiteSpace($gatewayToken)) {
    throw 'This script must be launched as the child of aigw run.'
}

$resolvedMainHap = Resolve-WorkspaceFile -Path $MainHap
$resolvedTestHap = Resolve-WorkspaceFile -Path $TestHap
$script:Hdc = (Get-Command $HdcPath -ErrorAction Stop).Source
$node = (Get-Command node -ErrorAction Stop).Source
$bridgeScript = Join-Path $workspaceRoot 'tools\gateway-device-bridge.mjs'
$bridgeReady = Join-Path $runDirectory 'bridge-ready.json'
$bridgeSummary = Join-Path $runDirectory 'bridge-summary.json'
$bridgeStdout = Join-Path $logsDirectory 'bridge.stdout.log'
$bridgeStderr = Join-Path $logsDirectory 'bridge.stderr.log'
$bridgeProcess = $null
$reverseCreated = $false
$installed = $false
$testModuleInstalled = $false
$preservedExistingMain = $false
$testPassed = $false
$uninstalled = $false
$reverseRemoved = $false
$bridgeStopped = $false
$failure = $null

try {
    $targets = Invoke-HdcLogged -Arguments @('list', 'targets') -LogName 'device-targets.log'
    $targetLines = @($targets -split '\r?\n' | Where-Object {
        $_.Trim().Length -gt 0 -and $_ -notmatch '^\[Empty\]$'
    })
    if ($targetLines.Count -ne 1) {
        throw "Exactly one HDC target is required; found $($targetLines.Count)."
    }

    $preexistingNamed = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
        -LogName 'preinstall-bundle-probe.log' -AllowFailure
    $preexistingAll = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
        -LogName 'preinstall-bundle-list.log' -AllowFailure
    $escapedBundle = [regex]::Escape($BundleName)
    $bundleExists = $preexistingNamed -match $escapedBundle -or
        $preexistingAll -match ('(?m)^\s*' + $escapedBundle + '\s*$')
    if ($PreserveExistingMain) {
        if (-not $bundleExists -or
            $preexistingNamed -notmatch '"moduleName"\s*:\s*"test_host"') {
            throw "Bundle $BundleName must already contain the test_host main module."
        }
        if ($preexistingNamed -match '"moduleName"\s*:\s*"test_host_test"') {
            throw 'The test_host_test module is already installed; refusing to replace or remove it.'
        }
        $preservedExistingMain = $true
    } elseif ($bundleExists) {
        throw "Bundle $BundleName is already installed; refusing to replace or remove it."
    }

    $preexistingForwards = Invoke-HdcLogged -Arguments @('fport', 'ls') `
        -LogName 'preinstall-forward-list.log' -AllowFailure
    if ($preexistingForwards -match [regex]::Escape("tcp:$DevicePort")) {
        throw "Device port tcp:$DevicePort already has a forwarding rule; refusing to replace it."
    }

    $bridgeArguments = @(
        "`"$bridgeScript`"",
        '--ready-file', "`"$bridgeReady`"",
        '--summary-file', "`"$bridgeSummary`""
    )
    $bridgeProcess = Start-Process -FilePath $node -ArgumentList $bridgeArguments -PassThru `
        -WindowStyle Hidden -RedirectStandardOutput $bridgeStdout -RedirectStandardError $bridgeStderr
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $bridgeReady)) {
        $bridgeProcess.Refresh()
        if ($bridgeProcess.HasExited) {
            throw 'Gateway device bridge exited before becoming ready.'
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw 'Gateway device bridge did not become ready within 10 seconds.'
        }
        Start-Sleep -Milliseconds 100
    }
    $ready = Get-Content -LiteralPath $bridgeReady -Raw | ConvertFrom-Json
    $bridgePort = [int]$ready.port
    if ($bridgePort -lt 1 -or $bridgePort -gt 65535 -or $ready.gatewayCredentialRecorded -ne $false) {
        throw 'Gateway device bridge ready record is invalid.'
    }

    Invoke-HdcLogged -Arguments @('rport', "tcp:$DevicePort", "tcp:$bridgePort") `
        -LogName 'reverse-port-create.log' | Out-Null
    $reverseCreated = $true

    if (-not $PreserveExistingMain) {
        $mainInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedMainHap) `
            -LogName 'install-main.log'
        Assert-InstallSucceeded -Output $mainInstall -Kind 'Main'
        $installed = $true
    }
    $testInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedTestHap) `
        -LogName 'install-test.log'
    Assert-InstallSucceeded -Output $testInstall -Kind 'ohosTest'
    $testModuleInstalled = $true

    $testOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'LocalAIGatewayDevice',
        '-s', 'gatewayPort', [string]$DevicePort,
        '-s', 'timeout', '90000'
    ) -LogName 'device-test.log'
    if ($testOutput -notmatch 'Tests run:\s*2, Failure:\s*0, Error:\s*0, Pass:\s*2') {
        throw 'Local AI Gateway device suite did not report 2/2 passing.'
    }
    $testPassed = $true
} catch {
    $failure = $_
} finally {
    [Environment]::SetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', $null, 'Process')
    $gatewayToken = $null
    if ($reverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$DevicePort", "tcp:$bridgePort") `
            -LogName 'reverse-port-remove.log' -AllowFailure | Out-Null
        $forwardList = Invoke-HdcLogged -Arguments @('fport', 'ls') `
            -LogName 'reverse-port-postcheck.log' -AllowFailure
        $reverseRemoved = $forwardList -notmatch (
            [regex]::Escape("tcp:$DevicePort") + '\s+' + [regex]::Escape("tcp:$bridgePort"))
    }
    if ($null -ne $bridgeProcess) {
        $bridgeProcess.Refresh()
        if (-not $bridgeProcess.HasExited) {
            Stop-Process -Id $bridgeProcess.Id -Force
            $bridgeProcess.WaitForExit(5000) | Out-Null
        }
        $bridgeStopped = $bridgeProcess.HasExited
    }
    if ($PreserveExistingMain -and $testModuleInstalled) {
        Invoke-HdcLogged -Arguments @('shell', 'bm', 'uninstall', '-n', $BundleName,
            '-m', 'test_host_test') -LogName 'uninstall-test-module.log' -AllowFailure | Out-Null
        $preserved = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
            -LogName 'post-uninstall-preserved-main.log' -AllowFailure
        $uninstalled = $preserved -match '"moduleName"\s*:\s*"test_host"' -and
            $preserved -notmatch '"moduleName"\s*:\s*"test_host_test"'
    } elseif ($installed) {
        Invoke-HdcLogged -Arguments @('uninstall', $BundleName) `
            -LogName 'uninstall.log' -AllowFailure | Out-Null
        $named = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
            -LogName 'post-uninstall-bundle-probe.log' -AllowFailure
        $all = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
            -LogName 'post-uninstall-bundle-list.log' -AllowFailure
        $escaped = [regex]::Escape($BundleName)
        $uninstalled = $named -notmatch $escaped -and $all -notmatch ('(?m)^\s*' + $escaped + '\s*$')
    }
}

$completed = $testPassed -and $uninstalled -and $reverseRemoved -and $bridgeStopped
$summary = [ordered]@{
    schemaVersion = '1.0'
    timestamp = $timestamp
    bundle = $BundleName
    module = 'test_host_test'
    devicePort = $DevicePort
    testClass = 'LocalAIGatewayDevice'
    testsPassed = $testPassed
    gatewayCredentialRecorded = $false
    rawProviderResponseRecorded = $false
    preserveExistingMain = [bool]$PreserveExistingMain
    preservedExistingMain = $preservedExistingMain
    mainInstalledByScript = $installed
    testModuleInstalledByScript = $testModuleInstalled
    reverseRemoved = $reverseRemoved
    bridgeStopped = $bridgeStopped
    uninstalled = $uninstalled
    completed = $completed
}
[IO.File]::WriteAllText(
    (Join-Path $runDirectory 'acceptance-summary.json'),
    ($summary | ConvertTo-Json -Depth 4) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
)

if (-not $completed) {
    if ($null -ne $failure) {
        throw "Local AI Gateway device acceptance failed: $($failure.Exception.Message). See $runDirectory"
    }
    throw "Local AI Gateway device acceptance did not complete. See $runDirectory"
}

Write-Host "Local AI Gateway device acceptance passed. Evidence: $runDirectory"
