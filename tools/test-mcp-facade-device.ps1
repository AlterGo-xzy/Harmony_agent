[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MainHap,

    [Parameter(Mandatory = $true)]
    [string]$TestHap,

    [string]$HdcPath = 'D:\DevEco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',

    [ValidateRange(1, 65535)]
    [int]$DevicePort = 4011,

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
$runDirectory = Join-Path $workspaceRoot "artifacts\t30-s2-mcp-facade-device\$timestamp"
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

$resolvedMainHap = Resolve-WorkspaceFile -Path $MainHap
$resolvedTestHap = Resolve-WorkspaceFile -Path $TestHap
$script:Hdc = (Get-Command $HdcPath -ErrorAction Stop).Source
$node = (Get-Command node -ErrorAction Stop).Source
$fixtureScript = Join-Path $workspaceRoot 'tools\fixture\fixture-server.mjs'
$fixtureReady = Join-Path $runDirectory 'fixture-ready.json'
$fixtureStdout = Join-Path $logsDirectory 'fixture.stdout.log'
$fixtureStderr = Join-Path $logsDirectory 'fixture.stderr.log'
$fixtureProcess = $null
$reverseCreated = $false
$hostPort = 0
$installedMain = $false
$installedTest = $false
$preservedExistingMain = $false
$testPassed = $false
$uninstalled = $false
$reverseRemoved = $false
$fixtureStopped = $false
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
    if ($preexistingForwards -match [regex]::Escape("tcp:$DevicePort")) {
        throw "Device port tcp:$DevicePort already has a forwarding rule; refusing to replace it."
    }

    $fixtureArguments = @(
        "`"$fixtureScript`"", '--host', '127.0.0.1', '--port', '0',
        '--ready-file', "`"$fixtureReady`""
    )
    $fixtureProcess = Start-Process -FilePath $node -ArgumentList $fixtureArguments -PassThru `
        -WindowStyle Hidden -RedirectStandardOutput $fixtureStdout -RedirectStandardError $fixtureStderr
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $fixtureReady)) {
        $fixtureProcess.Refresh()
        if ($fixtureProcess.HasExited) {
            throw 'MCP fixture server exited before becoming ready.'
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw 'MCP fixture server did not become ready within 10 seconds.'
        }
        Start-Sleep -Milliseconds 100
    }
    $ready = Get-Content -LiteralPath $fixtureReady -Raw | ConvertFrom-Json
    $hostPort = [int]$ready.port
    if ($hostPort -lt 1 -or $hostPort -gt 65535) {
        throw 'MCP fixture ready record is invalid.'
    }
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:$hostPort/health" -TimeoutSec 5
    if ($health.ready -ne $true) {
        throw 'MCP fixture health check failed.'
    }

    Invoke-HdcLogged -Arguments @('rport', "tcp:$DevicePort", "tcp:$hostPort") `
        -LogName 'reverse-port-create.log' | Out-Null
    $reverseCreated = $true

    if (-not $PreserveExistingMain) {
        $mainInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedMainHap) `
            -LogName 'install-main.log'
        $installedMain = $true
        Assert-InstallSucceeded -Output $mainInstall -Kind 'Main'
    }
    $testInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedTestHap) `
        -LogName 'install-test.log'
    $installedTest = $true
    Assert-InstallSucceeded -Output $testInstall -Kind 'ohosTest'

    $testOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'McpFacadeDevice',
        '-s', 'fixtureUrl', "http://127.0.0.1:$DevicePort",
        '-s', 'timeout', '90000'
    ) -LogName 'device-test.log'
    if ($testOutput -notmatch 'Tests run:\s*1, Failure:\s*0, Error:\s*0, Pass:\s*1') {
        throw 'MCP Facade device suite did not report 1/1 passing.'
    }
    $testPassed = $true
} catch {
    $failure = $_
} finally {
    if ($reverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$DevicePort", "tcp:$hostPort") `
            -LogName 'reverse-port-remove.log' -AllowFailure | Out-Null
        $forwardList = Invoke-HdcLogged -Arguments @('fport', 'ls') `
            -LogName 'reverse-port-postcheck.log' -AllowFailure
        $reverseRemoved = $forwardList -notmatch (
            [regex]::Escape("tcp:$DevicePort") + '\s+' + [regex]::Escape("tcp:$hostPort"))
    }
    if ($null -ne $fixtureProcess) {
        $fixtureProcess.Refresh()
        if (-not $fixtureProcess.HasExited) {
            Stop-Process -Id $fixtureProcess.Id -Force
            $fixtureProcess.WaitForExit(5000) | Out-Null
        }
        $fixtureStopped = $fixtureProcess.HasExited
    }
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
        $uninstalled = $named -notmatch $escaped -and $all -notmatch ('(?m)^\s*' + $escaped + '\s*$')
    }
}

$completed = $testPassed -and $uninstalled -and $reverseRemoved -and $fixtureStopped
$summary = [ordered]@{
    schemaVersion = '1.0'
    timestamp = $timestamp
    bundle = $BundleName
    module = 'test_host_test'
    devicePort = $DevicePort
    testClass = 'McpFacadeDevice'
    testsPassed = $testPassed
    expectedToolCalls = 1
    preserveExistingMain = [bool]$PreserveExistingMain
    preservedExistingMain = $preservedExistingMain
    mainInstalledByScript = $installedMain
    testModuleInstalledByScript = $installedTest
    reverseRemoved = $reverseRemoved
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
        throw "MCP Facade device acceptance failed: $($failure.Exception.Message). See $runDirectory"
    }
    throw "MCP Facade device acceptance did not complete. See $runDirectory"
}

Write-Host "MCP Facade device acceptance passed. Evidence: $runDirectory"
