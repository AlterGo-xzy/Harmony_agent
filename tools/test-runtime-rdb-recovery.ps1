[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MainHap,

    [Parameter(Mandatory = $true)]
    [string]$TestHap,

    [string]$HdcPath = 'hdc',

    [string]$BundleName = 'com.harmony.agent',

    [string]$ModuleName = 'test_host_test'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$projectRootPath = [System.IO.Path]::GetFullPath($projectRoot).TrimEnd('\')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDirectory = Join-Path $projectRoot "artifacts\t26-rdb-runtime-recovery\$timestamp"
$logsDirectory = Join-Path $runDirectory 'logs'
New-Item -ItemType Directory -Force -Path $logsDirectory | Out-Null

function Resolve-WorkspaceFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($projectRootPath + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Acceptance input must stay inside $projectRootPath"
    }
    if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
        throw "Acceptance input is not a file: $resolved"
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
    [System.IO.File]::WriteAllText(
        (Join-Path $logsDirectory $LogName),
        $output,
        [System.Text.UTF8Encoding]::new($false)
    )
    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw "hdc failed with exit code $exitCode. See $LogName"
    }
    return $output
}

function Assert-OnePassingTest {
    param(
        [Parameter(Mandatory = $true)][string]$Output,
        [Parameter(Mandatory = $true)][string]$Phase
    )
    if ($Output -notmatch 'Tests run:\s*1, Failure:\s*0, Error:\s*0, Pass:\s*1') {
        throw "Runtime RDB $Phase phase did not report 1/1 passing."
    }
}

$resolvedMainHap = Resolve-WorkspaceFile -Path $MainHap
$resolvedTestHap = Resolve-WorkspaceFile -Path $TestHap
$script:Hdc = (Get-Command $HdcPath -ErrorAction Stop).Source
$installed = $false
$seedPassed = $false
$recoverPassed = $false
$processStopped = $false
$uninstalled = $false
$failure = $null

try {
    $targets = Invoke-HdcLogged -Arguments @('list', 'targets') -LogName 'device-targets.log'
    $targetLines = @($targets -split '\r?\n' | Where-Object {
        $_.Trim().Length -gt 0 -and $_ -notmatch '^\[Empty\]$'
    })
    if ($targetLines.Count -ne 1) {
        throw "Exactly one HDC target is required; found $($targetLines.Count)."
    }

    Invoke-HdcLogged -Arguments @('install', '-r', $resolvedMainHap) `
        -LogName 'install-main.log' | Out-Null
    $installed = $true
    Invoke-HdcLogged -Arguments @('install', '-r', $resolvedTestHap) `
        -LogName 'install-test.log' | Out-Null

    $seed = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', $ModuleName,
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'RuntimeRdbDeviceRecovery',
        '-s', 'recoveryPhase', 'seed',
        '-s', 'timeout', '60000'
    ) -LogName 'seed-phase.log'
    Assert-OnePassingTest -Output $seed -Phase 'seed'
    $seedPassed = $true

    $pidBeforeStop = Invoke-HdcLogged -Arguments @('shell', 'pidof', $BundleName) `
        -LogName 'process-before-force-stop.log' -AllowFailure
    if ($pidBeforeStop -notmatch '(?m)^\s*\d+(?:\s+\d+)*\s*$') {
        throw 'The bundle process was not running after the seed phase; force-stop evidence cannot be established.'
    }
    Invoke-HdcLogged -Arguments @('shell', 'aa', 'force-stop', $BundleName) `
        -LogName 'force-stop.log' | Out-Null
    $pidAfterStop = Invoke-HdcLogged -Arguments @('shell', 'pidof', $BundleName) `
        -LogName 'process-after-force-stop.log' -AllowFailure
    if ($pidAfterStop -match '(?m)^\s*\d+(?:\s+\d+)*\s*$') {
        throw 'The bundle process is still running after force-stop.'
    }
    $processStopped = $true

    $recover = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', $ModuleName,
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'RuntimeRdbDeviceRecovery',
        '-s', 'recoveryPhase', 'recover',
        '-s', 'timeout', '60000'
    ) -LogName 'recover-phase.log'
    Assert-OnePassingTest -Output $recover -Phase 'recover'
    $recoverPassed = $true
} catch {
    $failure = $_
} finally {
    if ($installed) {
        Invoke-HdcLogged -Arguments @('uninstall', $BundleName) `
            -LogName 'uninstall.log' -AllowFailure | Out-Null
        $probe = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
            -LogName 'post-uninstall-bundle-probe.log' -AllowFailure
        $bundleList = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
            -LogName 'post-uninstall-bundle-list.log' -AllowFailure
        $escapedBundleName = [regex]::Escape($BundleName)
        $namedProbeContainsBundle = $probe -match $escapedBundleName
        $fullListContainsBundle = $bundleList -match ('(?m)^\s*' + $escapedBundleName + '\s*$')
        $uninstalled = -not $namedProbeContainsBundle -and -not $fullListContainsBundle
    }
}

$completed = $seedPassed -and $processStopped -and $recoverPassed -and $uninstalled
$summary = [ordered]@{
    timestamp = $timestamp
    bundle = $BundleName
    module = $ModuleName
    mainHap = $resolvedMainHap.Substring($projectRootPath.Length + 1).Replace('\', '/')
    testHap = $resolvedTestHap.Substring($projectRootPath.Length + 1).Replace('\', '/')
    seedPhase = if ($seedPassed) { 'passed' } else { 'failed' }
    processBoundary = if ($processStopped) { 'force-stop verified by pidof before and after' } else { 'failed' }
    recoverPhase = if ($recoverPassed) { 'passed' } else { 'failed' }
    uninstalled = $uninstalled
    completed = $completed
}
[System.IO.File]::WriteAllText(
    (Join-Path $runDirectory 'acceptance-summary.json'),
    ($summary | ConvertTo-Json -Depth 3) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

if (-not $completed) {
    if ($null -ne $failure) {
        throw "Runtime RDB recovery acceptance failed: $($failure.Exception.Message). See $runDirectory"
    }
    throw "Runtime RDB recovery acceptance did not complete. See $runDirectory"
}

Write-Host "Runtime RDB recovery acceptance passed. Evidence: $runDirectory"
