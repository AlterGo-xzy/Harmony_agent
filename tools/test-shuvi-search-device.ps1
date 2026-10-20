[CmdletBinding()]
param(
    [string]$MainHap = '.\test_host\build\default\outputs\default\test_host-default-unsigned.hap',
    [string]$TestHap = '.\test_host\build\default\outputs\ohosTest\test_host-ohosTest-unsigned.hap',
    [string]$SearchServiceRoot = 'D:\Shuvi-agent\services\search-mcp',
    [string]$HdcPath = 'D:\DevEco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe',
    [ValidateRange(1, 65535)]
    [int]$SearchHostPort = 8787,
    [ValidateRange(1, 65535)]
    [int]$SearchDevicePort = 8787,
    [ValidateRange(1, 65535)]
    [int]$FixtureDevicePort = 8788,
    [string]$BundleName = 'com.harmony.agent',
    [switch]$LiveSearch,
    [switch]$PreserveExistingBundle,
    [switch]$AllowDeviceChanges
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $AllowDeviceChanges) {
    throw 'Device installation, reverse forwarding, test execution, and uninstall require -AllowDeviceChanges.'
}
if ($SearchHostPort -ne $SearchDevicePort) {
    throw 'SearchHostPort must equal SearchDevicePort because the local search service validates the forwarded Host header.'
}

$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDirectory = Join-Path $workspaceRoot "artifacts\shuvi-search-device-acceptance\$timestamp"
$logsDirectory = Join-Path $runDirectory 'logs'
New-Item -ItemType Directory -Path $logsDirectory -Force | Out-Null

function Resolve-WorkspaceFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if (-not $resolved.StartsWith($workspaceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'HAP inputs must stay inside the Harmony Agent workspace.'
    }
    return $resolved
}

function Write-Log {
    param([string]$Name, [AllowEmptyString()][string]$Content)
    $safe = $Content -replace '(?i)(authorization\s*[:=]\s*)([^\r\n]+)', '$1[REDACTED]'
    $safe = $safe -replace '(?i)(bearer\s+)[A-Za-z0-9._~+/=-]+', '$1[REDACTED]'
    [IO.File]::WriteAllText((Join-Path $logsDirectory $Name), $safe, [Text.UTF8Encoding]::new($false))
}

function Invoke-HdcLogged {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$LogName,
        [ValidateRange(1, 600)][int]$TimeoutSeconds = 30,
        [switch]$AllowFailure
    )
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $script:Hdc
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        $output = $stdout.Result + $stderr.Result
        Write-Log -Name $LogName -Content $output
        throw "hdc timed out after $TimeoutSeconds seconds. See $LogName"
    }
    $output = $stdout.Result + $stderr.Result
    $exitCode = $process.ExitCode
    Write-Log -Name $LogName -Content $output
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

function Wait-TcpPort {
    param([int]$Port, [Diagnostics.Process]$Process, [string]$Name)
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while ([DateTime]::UtcNow -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) { throw "$Name exited before becoming ready." }
        $client = [Net.Sockets.TcpClient]::new()
        try {
            $pending = $client.ConnectAsync('127.0.0.1', $Port)
            if ($pending.Wait(250) -and $client.Connected) { return }
        } catch {
        } finally {
            $client.Dispose()
        }
        Start-Sleep -Milliseconds 100
    }
    throw "$Name did not listen on port $Port within 15 seconds."
}

function Stop-ChildProcess {
    param([AllowNull()][Diagnostics.Process]$Process)
    if ($null -eq $Process) { return $true }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        $Process.Kill($true)
        $Process.WaitForExit(5000) | Out-Null
    }
    return $Process.HasExited
}

function Test-TcpPortClosed {
    param([int]$Port)
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $pending = $client.ConnectAsync('127.0.0.1', $Port)
        return -not ($pending.Wait(500) -and $client.Connected)
    } catch {
        return $true
    } finally {
        $client.Dispose()
    }
}

$resolvedMainHap = Resolve-WorkspaceFile -Path $MainHap
$resolvedTestHap = Resolve-WorkspaceFile -Path $TestHap
$serviceRoot = (Resolve-Path -LiteralPath $SearchServiceRoot).Path
$script:Hdc = (Get-Command $HdcPath -ErrorAction Stop).Source
$npm = (Get-Command npm.cmd -ErrorAction Stop).Source
$node = (Get-Command node -ErrorAction Stop).Source
$fixtureScript = Join-Path $workspaceRoot 'tools\fixture\fixture-server.mjs'
$fixtureReady = Join-Path $runDirectory 'fixture-ready.json'
$searchStdout = Join-Path $logsDirectory 'search-service.stdout.log'
$searchStderr = Join-Path $logsDirectory 'search-service.stderr.log'
$fixtureStdout = Join-Path $logsDirectory 'fixture.stdout.log'
$fixtureStderr = Join-Path $logsDirectory 'fixture.stderr.log'
$searchProcess = $null
$fixtureProcess = $null
$searchReverseCreated = $false
$fixtureReverseCreated = $false
$installedMain = $false
$installedTest = $false
$preexistingBundle = $false
$searchPassed = $false
$transportPassed = $false
$securityStoragePassed = $false
$cleanupPassed = $false
$fixtureHostPort = 0
$failure = $null
$targetLines = @()

try {
    $targets = Invoke-HdcLogged -Arguments @('list', 'targets') -LogName 'device-targets.log'
    $targetLines = @($targets -split '\r?\n' | Where-Object {
        $_.Trim().Length -gt 0 -and $_ -notmatch '^\[Empty\]$'
    })
    if ($targetLines.Count -ne 1) { throw "Exactly one HDC target is required; found $($targetLines.Count)." }

    $preexistingAll = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
        -LogName 'preinstall-bundle-list.log' -AllowFailure
    if ($preexistingAll -match ('(?m)^\s*' + [regex]::Escape($BundleName) + '\s*$')) {
        $preexistingBundle = $true
        if (-not $PreserveExistingBundle) {
            throw "Bundle $BundleName is already installed; use -PreserveExistingBundle to keep it and install only the test module."
        }
    }
    $preexistingForwards = Invoke-HdcLogged -Arguments @('fport', 'ls') `
        -LogName 'preinstall-forward-list.log' -AllowFailure
    if ($preexistingForwards -match [regex]::Escape("tcp:$SearchDevicePort") -or
        $preexistingForwards -match [regex]::Escape("tcp:$FixtureDevicePort")) {
        throw 'One of the requested device reverse ports is already in use.'
    }

    $portDeadline = [DateTime]::UtcNow.AddSeconds(10)
    do {
        $listeners = @(Get-NetTCPConnection -LocalAddress '127.0.0.1' -LocalPort $SearchHostPort `
            -State Listen -ErrorAction SilentlyContinue)
        if ($listeners.Count -eq 0) { break }
        Start-Sleep -Milliseconds 250
    } while ([DateTime]::UtcNow -lt $portDeadline)
    if ($listeners.Count -gt 0) {
        throw "Host port $SearchHostPort is already in use by PID $($listeners[0].OwningProcess)."
    }
    if ($LiveSearch -and -not (Test-Path -LiteralPath (Join-Path $serviceRoot '.env')) -and
        [string]::IsNullOrWhiteSpace($env:TAVILY_API_KEY)) {
        throw 'Live search requires TAVILY_API_KEY in the process environment or search service .env file.'
    }

    $buildOutput = & $npm --prefix $serviceRoot run build 2>&1 | Out-String
    $buildExit = $LASTEXITCODE
    Write-Log -Name 'search-service-build.log' -Content $buildOutput
    if ($buildExit -ne 0) { throw 'Shuvi search MCP build failed.' }

    $searchEntry = Join-Path $serviceRoot 'dist\main.js'
    $searchProcess = Start-Process -FilePath $node `
        -ArgumentList @('--env-file-if-exists=.env', "`"$searchEntry`"") -WorkingDirectory $serviceRoot `
        -Environment @{ PORT = $SearchHostPort.ToString() } -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $searchStdout -RedirectStandardError $searchStderr
    Wait-TcpPort -Port $SearchHostPort -Process $searchProcess -Name 'Shuvi search MCP'

    $fixtureArguments = @(
        "`"$fixtureScript`"", '--host', '127.0.0.1', '--port', '0',
        '--ready-file', "`"$fixtureReady`""
    )
    $fixtureProcess = Start-Process -FilePath $node -ArgumentList $fixtureArguments -PassThru `
        -WindowStyle Hidden -RedirectStandardOutput $fixtureStdout -RedirectStandardError $fixtureStderr
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $fixtureReady)) {
        $fixtureProcess.Refresh()
        if ($fixtureProcess.HasExited) { throw 'MCP fixture exited before becoming ready.' }
        if ([DateTime]::UtcNow -ge $deadline) { throw 'MCP fixture did not become ready within 10 seconds.' }
        Start-Sleep -Milliseconds 100
    }
    $ready = Get-Content -LiteralPath $fixtureReady -Raw | ConvertFrom-Json
    $fixtureHostPort = [int]$ready.port

    Invoke-HdcLogged -Arguments @('rport', "tcp:$SearchDevicePort", "tcp:$SearchHostPort") `
        -LogName 'search-reverse-create.log' | Out-Null
    $searchReverseCreated = $true
    Invoke-HdcLogged -Arguments @('rport', "tcp:$FixtureDevicePort", "tcp:$fixtureHostPort") `
        -LogName 'fixture-reverse-create.log' | Out-Null
    $fixtureReverseCreated = $true

    if (-not $preexistingBundle) {
        $mainInstall = Invoke-HdcLogged -Arguments @('install', '-w 180', $resolvedMainHap) `
            -LogName 'install-main.log' -TimeoutSeconds 220
        Assert-InstallSucceeded -Output $mainInstall -Kind 'Main'
        $installedMain = $true
    }
    $testInstall = Invoke-HdcLogged -Arguments @('install', '-r', '-w 180', $resolvedTestHap) `
        -LogName 'install-test.log' -TimeoutSeconds 220
    Assert-InstallSucceeded -Output $testInstall -Kind 'ohosTest'
    $installedTest = $true

    $mode = if ($LiveSearch) { 'live' } else { 'configuration' }
    $searchOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'ShuviWebSearchDevice',
        '-s', 'searchUrl', "http://127.0.0.1:$SearchDevicePort/mcp",
        '-s', 'searchMode', $mode,
        '-s', 'timeout', '90000'
    ) -LogName 'shuvi-search-device-test.log' -TimeoutSeconds 100
    if ($searchOutput -notmatch 'Tests run:\s*1, Failure:\s*0, Error:\s*0, Pass:\s*1') {
        throw 'Shuvi search device suite did not report 1/1 passing.'
    }
    $searchPassed = $true

    $transportOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'McpDeviceSmoke',
        '-s', 'fixtureUrl', "http://127.0.0.1:$FixtureDevicePort",
        '-s', 'timeout', '120000'
    ) -LogName 'mcp-transport-device-test.log' -TimeoutSeconds 150
    if ($transportOutput -match 'Failure:\s*[1-9]' -or $transportOutput -match 'Error:\s*[1-9]' -or
        $transportOutput -notmatch 'Failure:\s*0, Error:\s*0') {
        throw 'MCP transport device suite reported a failure.'
    }
    $stats = Invoke-RestMethod -Uri "http://127.0.0.1:$fixtureHostPort/__fixture/stats" -TimeoutSec 5
    $statsJson = $stats | ConvertTo-Json -Depth 8
    Write-Log -Name 'fixture-stats.json' -Content ($statsJson + [Environment]::NewLine)
    if ([int]$stats.cancelledRequests -lt 1 -or [int]$stats.expiredSessions -ne 1 -or
        [int]$stats.deleteRequests -lt 1) {
        throw 'Fixture did not observe cancellation, one expired session, and session deletion.'
    }
    $transportPassed = $true

    $securityOutput = Invoke-HdcLogged -Arguments @(
        'shell', 'aa', 'test', '-b', $BundleName, '-m', 'test_host_test',
        '-s', 'unittest', 'OpenHarmonyTestRunner',
        '-s', 'class', 'SecurityStorageDevice',
        '-s', 'timeout', '120000'
    ) -LogName 'security-storage-device-test.log' -TimeoutSeconds 150
    if ($securityOutput -match 'Failure:\s*[1-9]' -or $securityOutput -match 'Error:\s*[1-9]' -or
        $securityOutput -notmatch 'Tests run:\s*2, Failure:\s*0, Error:\s*0, Pass:\s*2') {
        throw 'Security storage device suite did not report 2/2 passing.'
    }
    $securityStoragePassed = $true
} catch {
    $failure = $_
} finally {
    if ($fixtureReverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$FixtureDevicePort", "tcp:$fixtureHostPort") `
            -LogName 'fixture-reverse-remove.log' -AllowFailure | Out-Null
    }
    if ($searchReverseCreated) {
        Invoke-HdcLogged -Arguments @('fport', 'rm', "tcp:$SearchDevicePort", "tcp:$SearchHostPort") `
            -LogName 'search-reverse-remove.log' -AllowFailure | Out-Null
    }
    if ($installedMain) {
        Invoke-HdcLogged -Arguments @('uninstall', $BundleName) -LogName 'uninstall.log' -AllowFailure | Out-Null
    } elseif ($installedTest -and $preexistingBundle) {
        Invoke-HdcLogged -Arguments @(
            'shell', 'bm', 'uninstall', '-n', $BundleName, '-m', 'test_host_test'
        ) -LogName 'uninstall-test-module.log' -AllowFailure | Out-Null
    }
    $fixtureStopped = Stop-ChildProcess -Process $fixtureProcess
    $searchStopped = Stop-ChildProcess -Process $searchProcess
    $postForwards = Invoke-HdcLogged -Arguments @('fport', 'ls') -LogName 'post-forward-list.log' -AllowFailure
    $postBundles = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-a') `
        -LogName 'post-bundle-list.log' -AllowFailure
    $postBundleDetail = Invoke-HdcLogged -Arguments @('shell', 'bm', 'dump', '-n', $BundleName) `
        -LogName 'post-bundle-detail.log' -AllowFailure
    $bundleCleanupPassed = if ($preexistingBundle) {
        $postBundles -match ('(?m)^\s*' + [regex]::Escape($BundleName) + '\s*$') -and
            $postBundleDetail -notmatch [regex]::Escape('test_host_test')
    } else {
        $postBundles -notmatch ('(?m)^\s*' + [regex]::Escape($BundleName) + '\s*$')
    }
    $searchPortClosed = Test-TcpPortClosed -Port $SearchHostPort
    $cleanupPassed = $fixtureStopped -and $searchStopped -and $searchPortClosed -and
        $postForwards -notmatch [regex]::Escape("tcp:$SearchDevicePort") -and
        $postForwards -notmatch [regex]::Escape("tcp:$FixtureDevicePort") -and
        $bundleCleanupPassed
}

$summary = [ordered]@{
    schemaVersion = '1.0'
    timestamp = $timestamp
    deviceTarget = if ($null -ne $targetLines -and $targetLines.Count -eq 1) { $targetLines[0].Trim() } else { $null }
    searchMode = if ($LiveSearch) { 'live' } else { 'configuration' }
    searchHostPort = $SearchHostPort
    searchDevicePort = $SearchDevicePort
    liveSearchExecuted = [bool]$LiveSearch
    preexistingBundlePreserved = $preexistingBundle
    searchDevicePassed = $searchPassed
    transportLifecyclePassed = $transportPassed
    securityStoragePassed = $securityStoragePassed
    cleanupPassed = $cleanupPassed
    mainHapSha256 = (Get-FileHash -LiteralPath $resolvedMainHap -Algorithm SHA256).Hash
    testHapSha256 = (Get-FileHash -LiteralPath $resolvedTestHap -Algorithm SHA256).Hash
    completed = $searchPassed -and $transportPassed -and $securityStoragePassed -and $cleanupPassed
    failure = if ($null -eq $failure) { $null } else { $failure.Exception.Message }
    blocker = if ($LiveSearch) { $null } else { 'TAVILY_API_KEY is not configured; real upstream search was not executed.' }
}
[IO.File]::WriteAllText(
    (Join-Path $runDirectory 'acceptance-summary.json'),
    ($summary | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
)

if (-not $summary.completed) {
    if ($null -ne $failure) {
        throw "Shuvi search device acceptance failed: $($failure.Exception.Message). See $runDirectory"
    }
    throw "Shuvi search device acceptance did not complete. See $runDirectory"
}

Write-Host "Shuvi search device acceptance passed. Evidence: $runDirectory"
