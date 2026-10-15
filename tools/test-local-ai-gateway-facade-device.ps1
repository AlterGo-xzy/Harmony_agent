[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MainHap,

    [Parameter(Mandatory = $true)]
    [string]$TestHap,

    [string]$HdcPath = 'D:\DevEco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',

    [ValidateRange(1, 65535)]
    [int]$GatewayDevicePort = 4012,

    [ValidateRange(1, 65535)]
    [int]$McpDevicePort = 4013,

    [string]$BundleName = 'com.harmony.agent',

    [switch]$PreserveExistingMain,

    [switch]$AllowDeviceChanges
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $AllowDeviceChanges) {
    throw 'Signing/install preparation, reverse forwarding, real Provider invocation, test execution, and uninstall require -AllowDeviceChanges.'
}
if ($GatewayDevicePort -eq $McpDevicePort) {
    throw 'GatewayDevicePort and McpDevicePort must be different.'
}

$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDirectory = Join-Path $workspaceRoot "artifacts\t36-local-ai-gateway-facade-device\$timestamp-device"
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

function Wait-ReadyFile {
    param(
        [Parameter(Mandatory = $true)][Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind
    )
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $Path)) {
        $Process.Refresh()
        if ($Process.HasExited) {
            throw "$Kind exited before becoming ready."
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw "$Kind did not become ready within 10 seconds."
        }
        Start-Sleep -Milliseconds 100
    }
}

function Stop-OwnedProcess {
    param([Diagnostics.Process]$Process)
    if ($null -eq $Process) {
        return $true
    }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force
        $Process.WaitForExit(5000) | Out-Null
        $Process.Refresh()
    }
    return $Process.HasExited
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
$fixtureScript = Join-Path $workspaceRoot 'tools\fixture\fixture-server.mjs'
$bridgeReady = Join-Path $runDirectory 'bridge-ready.json'
$bridgeSummary = Join-Path $runDirectory 'bridge-summary.json'
$fixtureReady = Join-Path $runDirectory 'fixture-ready.json'
$bridgeProcess = $null
$fixtureProcess = $null
$gatewayHostPort = 0
$mcpHostPort = 0
$gatewayReverseCreated = $false
$mcpReverseCreated = $false
$gatewayReverseRemoved = $false
$mcpReverseRemoved = $false
$installedMain = $false
$installedTest = $false
$preservedExistingMain = $false
$testPassed = $false
$uninstalled = $false
$bridgeStopped = $false
$fixtureStopped = $false
$bridgeEvidencePassed = $false
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
        if (-not $bundleExists -or $preexistingNamed -notmatch '"moduleName"\s*:\s*"test_host"') {
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
    foreach ($devicePort in @($GatewayDevicePort, $McpDevicePort)) {
        if ($preexistingForwards -match [regex]::Escape("tcp:$devicePort")) {
            throw "Device port tcp:$devicePort already has a forwarding rule; refusing to replace it."
        }
    }

    $bridgeProcess = Start-Process -FilePath $node -ArgumentList @(
        "`"$bridgeScript`"", '--ready-file', "`"$bridgeReady`"",
        '--summary-file', "`"$bridgeSummary`""
    ) -PassThru -WindowStyle Hidden -WorkingDirectory $workspaceRoot `
        -RedirectStandardOutput (Join-Path $logsDirectory 'bridge.stdout.log') `
        -RedirectStandardError (Join-Path $logsDirectory 'bridge.stderr.log')
    Wait-ReadyFile -Process $bridgeProcess -Path $bridgeReady -Kind 'Gateway device bridge'
    $bridgeRecord = Get-Content -LiteralPath $bridgeReady -Raw | ConvertFrom-Json
    $gatewayHostPort = [int]$bridgeRecord.port
    if ($gatewayHostPort -lt 1 -or $gatewayHostPort -gt 65535 -or
        $bridgeRecord.gatewayCredentialRecorded -ne $false) {
        throw 'Gateway device bridge ready record is invalid.'
    }

    $fixtureProcess = Start-Process -FilePath $node -ArgumentList @(
        "`"$fixtureScript`"", '--host', '127.0.0.1', '--port', '0',
        '--ready-file', "`"$fixtureReady`""
    ) -PassThru -WindowStyle Hidden -WorkingDirectory $workspaceRoot `
        -RedirectStandardOutput (Join-Path $logsDirectory 'fixture.stdout.log') `
        -RedirectStandardError (Join-Path $logsDirectory 'fixture.stderr.log')
    Wait-ReadyFile -Process $fixtureProcess -Path $fixtureReady -Kind 'MCP fixture server'
    $fixtureRecord = Get-Content -LiteralPath $fixtureReady -Raw | ConvertFrom-Json
    $mcpHostPort = [int]$fixtureRecord.port
    if ($mcpHostPort -lt 1 -or $mcpHostPort -gt 65535) {
        throw 'MCP fixture ready record is invalid.'
    }
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:$mcpHostPort/health" -TimeoutSec 5
    if ($health.ready -ne $true) {
        throw 'MCP fixture health check failed.'
    }

    Invoke-HdcLogged -Arguments @('rport', "tcp:$GatewayDevicePort", "tcp:$gatewayHostPort") `
        -LogName 'gateway-reverse-create.log' | Out-Null
    $gatewayReverseCreated = $true
    Invoke-HdcLogged -Arguments @('rport', "tcp:$McpDevicePort", "tcp:$mcpHostPort") `
        -LogName 'mcp-reverse-create.log' | Out-Null
    $mcpReverseCreated = $true

    if (-not $PreserveExistingMain) {
        $mainInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedMainHap) `
            -LogName 'install-main.log'
        Assert-InstallSucceeded -Output $mainInstall -Kind 'Main'
        $installedMain = $true
    }
    $testInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedTestHap) `
        -LogName 'install-test.log'
    Assert-InstallSucceeded -Output $testInstall -Kind 'ohosTest'
    $installedTest = $true

    $testOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'LocalAIGatewayFacadeDevice',
        '-s', 'gatewayPort', [string]$GatewayDevicePort,
        '-s', 'mcpPort', [string]$McpDevicePort,
        '-s', 'timeout', '120000'
    ) -LogName 'device-test.log'
    if ($testOutput -notmatch 'Tests run:\s*1, Failure:\s*0, Error:\s*0, Pass:\s*1') {
        throw 'Local AI Gateway Facade device suite did not report 1/1 passing.'
    }
    $testPassed = $true

    $bridgeRecord = Get-Content -LiteralPath $bridgeSummary -Raw | ConvertFrom-Json
    $status200 = [int]($bridgeRecord.upstreamStatusCounts.'200')
    if ([int]$bridgeRecord.chatCount -ne 1 -or [int]$bridgeRecord.rejectedCount -ne 0 -or
        $status200 -ne 1 -or $bridgeRecord.gatewayCredentialRecorded -ne $false -or
        $bridgeRecord.requestBodyRecorded -ne $false -or $bridgeRecord.responseBodyRecorded -ne $false) {
        throw 'Gateway bridge evidence did not prove exactly one successful redacted Provider request.'
    }
    $bridgeEvidencePassed = $true
} catch {
    $failure = $_
} finally {
    [Environment]::SetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', $null, 'Process')
    $gatewayToken = $null
    if ($mcpReverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$McpDevicePort", "tcp:$mcpHostPort") `
            -LogName 'mcp-reverse-remove.log' -AllowFailure | Out-Null
    }
    if ($gatewayReverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$GatewayDevicePort", "tcp:$gatewayHostPort") `
            -LogName 'gateway-reverse-remove.log' -AllowFailure | Out-Null
    }
    if ($mcpReverseCreated -or $gatewayReverseCreated) {
        $forwardList = Invoke-HdcLogged -Arguments @('fport', 'ls') `
            -LogName 'reverse-postcheck.log' -AllowFailure
        $mcpReverseRemoved = -not $mcpReverseCreated -or
            $forwardList -notmatch [regex]::Escape("tcp:$McpDevicePort")
        $gatewayReverseRemoved = -not $gatewayReverseCreated -or
            $forwardList -notmatch [regex]::Escape("tcp:$GatewayDevicePort")
    }
    $fixtureStopped = Stop-OwnedProcess -Process $fixtureProcess
    $bridgeStopped = Stop-OwnedProcess -Process $bridgeProcess
    if ($PreserveExistingMain -and $installedTest) {
        Invoke-HdcLogged -Arguments @('shell', 'bm', 'uninstall', '-n', $BundleName,
            '-m', 'test_host_test') -LogName 'uninstall-test-module.log' -AllowFailure | Out-Null
        $preserved = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
            -LogName 'post-uninstall-preserved-main.log' -AllowFailure
        $uninstalled = $preserved -match '"moduleName"\s*:\s*"test_host"' -and
            $preserved -notmatch '"moduleName"\s*:\s*"test_host_test"'
    } elseif ($installedMain) {
        Invoke-HdcLogged -Arguments @('uninstall', $BundleName) `
            -LogName 'uninstall.log' -AllowFailure | Out-Null
        $named = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
            -LogName 'post-uninstall-bundle-probe.log' -AllowFailure
        $all = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
            -LogName 'post-uninstall-bundle-list.log' -AllowFailure
        $escaped = [regex]::Escape($BundleName)
        $uninstalled = $named -notmatch $escaped -and
            $all -notmatch ('(?m)^\s*' + $escaped + '\s*$')
    }
}

$completed = $testPassed -and $bridgeEvidencePassed -and $uninstalled -and
    $gatewayReverseRemoved -and $mcpReverseRemoved -and $bridgeStopped -and $fixtureStopped
$summary = [ordered]@{
    schemaVersion = '1.0'
    timestamp = $timestamp
    bundle = $BundleName
    module = 'test_host_test'
    testClass = 'LocalAIGatewayFacadeDevice'
    gatewayDevicePort = $GatewayDevicePort
    mcpDevicePort = $McpDevicePort
    testsPassed = $testPassed
    expectedProviderRequests = 1
    expectedToolCalls = 1
    bridgeEvidencePassed = $bridgeEvidencePassed
    gatewayCredentialRecorded = $false
    rawProviderResponseRecorded = $false
    preserveExistingMain = [bool]$PreserveExistingMain
    preservedExistingMain = $preservedExistingMain
    mainInstalledByScript = $installedMain
    testModuleInstalledByScript = $installedTest
    gatewayReverseRemoved = $gatewayReverseRemoved
    mcpReverseRemoved = $mcpReverseRemoved
    bridgeStopped = $bridgeStopped
    fixtureStopped = $fixtureStopped
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
        throw "Local AI Gateway Facade device acceptance failed: $($failure.Exception.Message). See $runDirectory"
    }
    throw "Local AI Gateway Facade device acceptance did not complete. See $runDirectory"
}

Write-Host "Local AI Gateway Facade device acceptance passed. Evidence: $runDirectory"
