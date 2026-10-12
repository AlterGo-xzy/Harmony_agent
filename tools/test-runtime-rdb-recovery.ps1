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

function Assert-InstallSucceeded {
    param(
        [Parameter(Mandatory = $true)][string]$Output,
        [Parameter(Mandatory = $true)][string]$PackageKind
    )
    if ($Output -notmatch '(?i)install bundle successfully') {
        throw "$PackageKind HAP installation did not report success."
    }
}

function Read-SharedText {
    param([Parameter(Mandatory = $true)][string]$Path)
    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
    try {
        $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::UTF8, $true, 1024, $true)
        try {
            return $reader.ReadToEnd()
        } finally {
            $reader.Dispose()
        }
    } finally {
        $stream.Dispose()
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
$seedProcess = $null

try {
    $targets = Invoke-HdcLogged -Arguments @('list', 'targets') -LogName 'device-targets.log'
    $targetLines = @($targets -split '\r?\n' | Where-Object {
        $_.Trim().Length -gt 0 -and $_ -notmatch '^\[Empty\]$'
    })
    if ($targetLines.Count -ne 1) {
        throw "Exactly one HDC target is required; found $($targetLines.Count)."
    }

    $mainInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedMainHap) `
        -LogName 'install-main.log'
    Assert-InstallSucceeded -Output $mainInstall -PackageKind 'Main'
    $installed = $true
    $testInstall = Invoke-HdcLogged -Arguments @('install', '-r', $resolvedTestHap) `
        -LogName 'install-test.log'
    Assert-InstallSucceeded -Output $testInstall -PackageKind 'ohosTest'

    $seedMarker = 'T26_SEED_READY'
    $seedArguments = @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', $ModuleName,
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'RuntimeRdbDeviceRecoverySeed',
        '-s', 'timeout', '600000'
    )
    $seedStdout = Join-Path $logsDirectory 'seed-phase.stdout.log'
    $seedStderr = Join-Path $logsDirectory 'seed-phase.stderr.log'
    $seedProcess = Start-Process -FilePath $script:Hdc -ArgumentList $seedArguments `
        -RedirectStandardOutput $seedStdout -RedirectStandardError $seedStderr `
        -WindowStyle Hidden -PassThru
    $readyDeadline = [DateTime]::UtcNow.AddSeconds(60)
    $pidBeforeStop = ''
    while ([DateTime]::UtcNow -lt $readyDeadline) {
        $seedOutput = if (Test-Path -LiteralPath $seedStdout) {
            Read-SharedText -Path $seedStdout
        } else {
            ''
        }
        $pidBeforeStop = Invoke-HdcLogged -Arguments @('shell', 'pidof', $BundleName) `
            -LogName 'process-before-force-stop.log' -AllowFailure
        if ($seedOutput -match [regex]::Escape($seedMarker) -and
            $pidBeforeStop -match '(?m)^\s*\d+(?:\s+\d+)*\s*$') {
            $seedPassed = $true
            break
        }
        $seedProcess.Refresh()
        if ($seedProcess.HasExited) {
            throw 'The seed test process exited before publishing its ready marker.'
        }
        Start-Sleep -Milliseconds 500
    }
    if (-not $seedPassed) {
        throw 'The seed phase did not publish a ready marker with a live bundle PID within 60 seconds.'
    }
    Invoke-HdcLogged -Arguments @('shell', 'aa', 'force-stop', $BundleName) `
        -LogName 'force-stop.log' | Out-Null
    if (-not $seedProcess.WaitForExit(10000)) {
        throw 'The background seed command did not exit after the bundle was force-stopped.'
    }
    $pidAfterStop = Invoke-HdcLogged -Arguments @('shell', 'pidof', $BundleName) `
        -LogName 'process-after-force-stop.log' -AllowFailure
    if ($pidAfterStop -match '(?m)^\s*\d+(?:\s+\d+)*\s*$') {
        throw 'The bundle process is still running after force-stop.'
    }
    $processStopped = $true

    $recover = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', $ModuleName,
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'RuntimeRdbDeviceRecoveryRecover',
        '-s', 'timeout', '60000'
    ) -LogName 'recover-phase.log'
    Assert-OnePassingTest -Output $recover -Phase 'recover'
    $recoverPassed = $true
} catch {
    $failure = $_
} finally {
    if ($null -ne $seedProcess) {
        $seedProcess.Refresh()
        if (-not $seedProcess.HasExited) {
            Invoke-HdcLogged -Arguments @('shell', 'aa', 'force-stop', $BundleName) `
                -LogName 'cleanup-force-stop.log' -AllowFailure | Out-Null
            $seedProcess.WaitForExit(10000) | Out-Null
        }
    }
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
    seedPhase = if ($seedPassed) { 'ready marker and live PID verified' } else { 'failed' }
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
