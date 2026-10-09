[CmdletBinding()]
param(
    [ValidateSet('Auto', 'Required', 'Skip')]
    [string]$Device = 'Auto',

    [ValidateSet('Modern', 'Legacy', 'Both')]
    [string]$Protocol = 'Both',

    [string]$HdcPath,

    [string]$AdvertiseHost,

    [switch]$InstallDependencies,

    [switch]$KeepTestApp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$resultsRoot = Join-Path $projectRoot 'artifacts\test-results'
$runDirectory = Join-Path $resultsRoot $runId
$logsDirectory = Join-Path $runDirectory 'logs'
$deliverablesDirectory = Join-Path $runDirectory 'deliverables'
[System.IO.Directory]::CreateDirectory($logsDirectory) | Out-Null
[System.IO.Directory]::CreateDirectory($deliverablesDirectory) | Out-Null

$script:Stages = [System.Collections.Generic.List[object]]::new()
$script:ExitCode = 0
$script:FixtureProcess = $null
$script:Hdc = $null
$script:SdkRoot = $null
$script:StudioRoot = $null
$script:Hvigor = $null
$script:DevEcoCli = $null
$script:FixtureInfo = $null
$script:InstalledBundle = $false
$script:DeviceTargets = @()
$script:HdcProbeReason = $null
$script:BundleName = 'com.harmony.agent'
$script:ProtocolVersions = @('2026-07-28', '2025-11-25')
$script:SigningAttempted = $false
$script:SigningGenerated = $false
$script:SigningCacheUsed = $false
$script:SigningPrepared = $false
$script:BuildProfileRestored = $true
$script:BuildProfileBackupPath = $null
$script:BuildProfileTemplateHash = $null
$script:SigningLockPath = $null
$script:SigningLockStream = $null
$script:HooksPathConfigured = $false
$script:HooksPathActive = $false

function Protect-Text {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return $null }
    $redacted = $Value -replace '(?i)(authorization\s*[:=]\s*)([^\r\n]+)', '$1[REDACTED]'
    $redacted = $redacted -replace '(?i)(bearer\s+)[A-Za-z0-9._~+/=-]+', '$1[REDACTED]'
    $redacted = $redacted -replace '(?i)(["'']?(?:storeFile|certpath|profile|keyAlias|keyPassword|keystorePassword)["'']?\s*[:=]\s*)("[^"]*"|''[^'']*''|[^\s,}]+)', '$1[REDACTED]'
    return $redacted
}

function Add-Stage {
    param(
        [string]$Name,
        [ValidateSet('PASSED', 'FAILED', 'SKIPPED')]
        [string]$Status,
        [long]$DurationMs,
        [AllowNull()][string]$Reason = $null,
        [AllowNull()][string]$Log = $null
    )
    $script:Stages.Add([pscustomobject]@{
        name = $Name
        status = $Status
        durationMs = $DurationMs
        protocol = $Protocol
        protocolVersions = $script:ProtocolVersions
        reason = Protect-Text $Reason
        log = $Log
    }) | Out-Null
}

function Invoke-Stage {
    param(
        [string]$Name,
        [scriptblock]$Action,
        [switch]$ConfigurationFailure
    )
    Write-Host "[$Name] RUNNING"
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $watch.Stop()
        Add-Stage -Name $Name -Status PASSED -DurationMs $watch.ElapsedMilliseconds
        Write-Host "[$Name] PASSED ($($watch.ElapsedMilliseconds) ms)"
    } catch {
        $watch.Stop()
        if ($ConfigurationFailure) { $script:ExitCode = 2 }
        elseif ($script:ExitCode -eq 0) { $script:ExitCode = 1 }
        Add-Stage -Name $Name -Status FAILED -DurationMs $watch.ElapsedMilliseconds -Reason $_.Exception.Message
        Write-Host "[$Name] FAILED: $(Protect-Text $_.Exception.Message)"
        throw
    }
}

function Add-SkippedStage {
    param([string]$Name, [string]$Reason)
    Add-Stage -Name $Name -Status SKIPPED -DurationMs 0 -Reason $Reason
    Write-Host "[$Name] SKIPPED: $Reason"
}

function Invoke-LoggedProcess {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$LogName,
        [hashtable]$Environment = @{}
    )
    $saved = @{}
    foreach ($key in $Environment.Keys) {
        $saved[$key] = [System.Environment]::GetEnvironmentVariable($key, 'Process')
        [System.Environment]::SetEnvironmentVariable($key, [string]$Environment[$key], 'Process')
    }
    try {
        $output = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        $text = Protect-Text (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
        $logPath = Join-Path $logsDirectory $LogName
        [System.IO.File]::WriteAllText($logPath, $text + [Environment]::NewLine,
            [System.Text.UTF8Encoding]::new($false))
        if ($text.Length -gt 0) { Write-Host $text }
        if ($exitCode -ne 0) {
            throw "Process failed with exit code $exitCode. See $logPath"
        }
        return $text
    } finally {
        foreach ($key in $Environment.Keys) {
            if ($null -eq $saved[$key]) {
                [System.Environment]::SetEnvironmentVariable($key, $null, 'Process')
            } else {
                [System.Environment]::SetEnvironmentVariable($key, [string]$saved[$key], 'Process')
            }
        }
    }
}

function Invoke-Hvigor {
    param([string[]]$Arguments, [string]$LogName)
    Invoke-LoggedProcess -FilePath $script:Hvigor -Arguments $Arguments -LogName $LogName -Environment @{
        DEVECO_SDK_HOME = $script:SdkRoot
    } | Out-Null
}

function Find-SdkRoot {
    $candidates = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($env:DEVECO_SDK_HOME)) {
        $candidates.Add($env:DEVECO_SDK_HOME)
    }
    $candidates.Add('D:\DevEco\DevEco Studio\sdk')
    $homeFile = Join-Path $env:LOCALAPPDATA 'Huawei\DevEcoStudio26.0\.home'
    if (Test-Path -LiteralPath $homeFile) {
        $studioHome = (Get-Content -LiteralPath $homeFile -Raw).Trim()
        if ($studioHome.Length -gt 0) { $candidates.Add((Join-Path $studioHome 'sdk')) }
    }
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Get-SafeGitArguments {
    $safeRoot = $projectRoot.Replace('\', '/')
    return @('-c', "safe.directory=$safeRoot", '-C', $projectRoot)
}

function Enable-RepositoryHooks {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.git'))) { return }
    $baseArguments = Get-SafeGitArguments
    $current = (& $git.Source @baseArguments config --local --get core.hooksPath 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) {
        throw 'Unable to inspect the repository-local Git hooks path.'
    }
    if ($current.Length -eq 0) {
        & $git.Source @baseArguments config --local core.hooksPath scripts/hooks
        if ($LASTEXITCODE -ne 0) { throw 'Unable to enable the repository pre-push hook.' }
        $script:HooksPathConfigured = $true
        $script:HooksPathActive = $true
    } elseif ($current -eq 'scripts/hooks') {
        $script:HooksPathActive = $true
    } elseif ($current -ne 'scripts/hooks') {
        Write-Warning "Existing repository hooks path '$current' was preserved; scripts/hooks/pre-push is not active."
    }
}

function Find-DevEcoCli {
    if (-not [string]::IsNullOrWhiteSpace($env:DEVECOCLI_BIN)) {
        $configured = Get-Command $env:DEVECOCLI_BIN -ErrorAction SilentlyContinue
        if ($null -ne $configured) { return $configured.Source }
        if (Test-Path -LiteralPath $env:DEVECOCLI_BIN -PathType Leaf) {
            return [System.IO.Path]::GetFullPath($env:DEVECOCLI_BIN)
        }
    }
    foreach ($name in @('devecocli', 'devecocli.cmd', 'devecocli.exe')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($null -ne $command) { return $command.Source }
    }
    return $null
}

function Close-SigningLock {
    if ($null -ne $script:SigningLockStream) {
        $script:SigningLockStream.Dispose()
        $script:SigningLockStream = $null
    }
    if (-not [string]::IsNullOrWhiteSpace($script:SigningLockPath) -and
        (Test-Path -LiteralPath $script:SigningLockPath -PathType Leaf)) {
        Remove-Item -LiteralPath $script:SigningLockPath -Force -ErrorAction SilentlyContinue
    }
    $script:SigningLockPath = $null
}

function Restore-BuildProfile {
    $buildProfile = Join-Path $projectRoot 'build-profile.json5'
    try {
        if (-not [string]::IsNullOrWhiteSpace($script:BuildProfileBackupPath) -and
            (Test-Path -LiteralPath $script:BuildProfileBackupPath -PathType Leaf)) {
            Copy-Item -LiteralPath $script:BuildProfileBackupPath -Destination $buildProfile -Force
            if (-not [string]::IsNullOrWhiteSpace($script:BuildProfileTemplateHash)) {
                $restoredHash = (Get-FileHash -LiteralPath $buildProfile -Algorithm SHA256).Hash
                if ($restoredHash -ne $script:BuildProfileTemplateHash) {
                    throw "build-profile.json5 restoration verification failed; backup retained at $($script:BuildProfileBackupPath)."
                }
            }
            Remove-Item -LiteralPath $script:BuildProfileBackupPath -Force
            $script:BuildProfileBackupPath = $null
        }
        $script:SigningPrepared = $false
        $script:BuildProfileRestored = $true
    } finally {
        Close-SigningLock
    }
}

function Invoke-PrivateDevEcoCli {
    param([string[]]$Arguments)
    $output = @(& $script:DevEcoCli @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ($exitCode -ne 0) {
        if ($text -match '(?i)(not logged in|auth login|sign in)') {
            throw 'DevEco authentication is required. Run devecocli auth login manually, then retry.'
        }
        throw "devecocli failed with exit code $exitCode while preparing device signing. Raw signing output was not logged."
    }
    return $text
}

function Prepare-DeviceSigning {
    $buildProfile = Join-Path $projectRoot 'build-profile.json5'
    $localDirectory = Join-Path $projectRoot '.local'
    $signedProfile = Join-Path $localDirectory 'build-profile.signed.json5'
    $templateHashFile = Join-Path $localDirectory 'build-profile.template.sha256'
    [System.IO.Directory]::CreateDirectory($localDirectory) | Out-Null

    $script:SigningLockPath = Join-Path $localDirectory 'signing.lock'
    try {
        $script:SigningLockStream = [System.IO.File]::Open(
            $script:SigningLockPath,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None)
    } catch {
        throw 'Another MCP signing operation is already using this repository.'
    }

    try {
        $templateText = Get-Content -LiteralPath $buildProfile -Raw
        if ($templateText -match '(?i)storeFile' -or $templateText -notmatch '"signingConfigs"\s*:\s*\[\s*\]') {
            throw 'build-profile.json5 is not the expected unsigned template; refusing to overwrite it.'
        }
        $script:BuildProfileTemplateHash = (Get-FileHash -LiteralPath $buildProfile -Algorithm SHA256).Hash
        $script:BuildProfileBackupPath = Join-Path $localDirectory "build-profile.template.$PID.$runId.bak"
        Copy-Item -LiteralPath $buildProfile -Destination $script:BuildProfileBackupPath
        $script:BuildProfileRestored = $false

        $cachedHash = if (Test-Path -LiteralPath $templateHashFile -PathType Leaf) {
            (Get-Content -LiteralPath $templateHashFile -Raw).Trim()
        } else { '' }
        $cacheValid = (Test-Path -LiteralPath $signedProfile -PathType Leaf) -and
            $cachedHash -eq $script:BuildProfileTemplateHash -and
            (Select-String -LiteralPath $signedProfile -Pattern 'storeFile' -Quiet)

        $script:SigningAttempted = $true
        if ($cacheValid) {
            Copy-Item -LiteralPath $signedProfile -Destination $buildProfile -Force
            $script:SigningCacheUsed = $true
        } else {
            $script:DevEcoCli = Find-DevEcoCli
            if ([string]::IsNullOrWhiteSpace($script:DevEcoCli)) {
                throw 'devecocli is required to generate an installable device-test HAP.'
            }
            $authText = Invoke-PrivateDevEcoCli -Arguments @('auth', 'status')
            if ($authText -notmatch 'Current user') {
                throw 'DevEco authentication is required. Run devecocli auth login manually, then retry.'
            }
            Invoke-PrivateDevEcoCli -Arguments @('signature', 'generate', '--product', 'default') | Out-Null
            if (-not (Select-String -LiteralPath $buildProfile -Pattern 'storeFile' -Quiet)) {
                throw 'DevEco reported signing success but did not produce a signed build-profile.json5.'
            }
            Copy-Item -LiteralPath $buildProfile -Destination $signedProfile -Force
            [System.IO.File]::WriteAllText(
                $templateHashFile,
                $script:BuildProfileTemplateHash + [Environment]::NewLine,
                [System.Text.UTF8Encoding]::new($false))
            $script:SigningGenerated = $true
        }

        if (-not (Select-String -LiteralPath $buildProfile -Pattern 'storeFile' -Quiet)) {
            throw 'The prepared build profile does not contain an installable signing configuration.'
        }
        $script:SigningPrepared = $true
    } catch {
        try { Restore-BuildProfile } catch { Write-Warning (Protect-Text $_.Exception.Message) }
        throw
    }
}

function Write-Reports {
    $finishedAt = Get-Date
    $persistentChanges = [System.Collections.Generic.List[string]]::new()
    if ($script:HooksPathActive) {
        $persistentChanges.Add('Repository-local Git core.hooksPath=scripts/hooks')
    }
    $signingCachePresent = Test-Path -LiteralPath (Join-Path $projectRoot '.local\build-profile.signed.json5') -PathType Leaf
    if ($signingCachePresent) {
        $persistentChanges.Add('Gitignored .local signing cache')
    }
    if ($script:SigningGenerated) {
        $persistentChanges.Add('DevEco-managed user signing material outside the repository')
    }
    $deliverables = @()
    if (Test-Path -LiteralPath $deliverablesDirectory -PathType Container) {
        $deliverables = @(Get-ChildItem -LiteralPath $deliverablesDirectory -File | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
                sizeBytes = $_.Length
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            }
        })
    }
    $summary = [pscustomobject]@{
        schemaVersion = 1
        project = '@harmony_agent/mcp-client'
        runId = $runId
        startedAt = $script:StartedAt.ToString('o')
        finishedAt = $finishedAt.ToString('o')
        durationMs = [long]($finishedAt - $script:StartedAt).TotalMilliseconds
        exitCode = $script:ExitCode
        deviceMode = $Device
        protocolMode = $Protocol
        protocolVersions = $script:ProtocolVersions
        implementation = 'custom ArkTS protocol client using @ohos.net.http'
        stages = $script:Stages
        deliverables = $deliverables
        environmentImpact = [pscustomobject]@{
            persistentChanges = @($persistentChanges)
            processEnvironment = @('DEVECO_SDK_HOME', 'MCP_FIXTURE_URL', 'MCP_PROTOCOL')
            fixtureBindHost = if ($null -eq $script:FixtureInfo) { $null } else { $script:FixtureInfo.host }
            fixtureProcessStopped = $null -eq $script:FixtureProcess -or $script:FixtureProcess.HasExited
            deviceTargetsDetected = $script:DeviceTargets.Count
            dependenciesInstalled = [bool]$InstallDependencies
            repositoryHookConfigured = $script:HooksPathActive
            signingAttempted = $script:SigningAttempted
            signingGenerated = $script:SigningGenerated
            signingCacheUsed = $script:SigningCacheUsed
            buildProfileRestored = $script:BuildProfileRestored
        }
    }
    $json = $summary | ConvertTo-Json -Depth 10
    $jsonPath = Join-Path $runDirectory 'test-results.json'
    [System.IO.File]::WriteAllText($jsonPath, $json + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $resultsRoot 'latest.json'), $json + [Environment]::NewLine,
        [System.Text.UTF8Encoding]::new($false))

    $passed = @($script:Stages | Where-Object status -eq 'PASSED').Count
    $failed = @($script:Stages | Where-Object status -eq 'FAILED').Count
    $skipped = @($script:Stages | Where-Object status -eq 'SKIPPED').Count
    $xml = [System.Text.StringBuilder]::new()
    [void]$xml.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
    [void]$xml.AppendLine("<testsuite name=`"harmony_agent MCP Acceptance`" tests=`"$($script:Stages.Count)`" failures=`"$failed`" skipped=`"$skipped`">")
    foreach ($stage in $script:Stages) {
        $name = [System.Security.SecurityElement]::Escape([string]$stage.name)
        $seconds = [math]::Round(([double]$stage.durationMs / 1000.0), 3).ToString([Globalization.CultureInfo]::InvariantCulture)
        [void]$xml.AppendLine("  <testcase name=`"$name`" time=`"$seconds`">")
        if ($stage.status -eq 'FAILED') {
            $reason = [System.Security.SecurityElement]::Escape([string]$stage.reason)
            [void]$xml.AppendLine("    <failure message=`"$reason`" />")
        } elseif ($stage.status -eq 'SKIPPED') {
            $reason = [System.Security.SecurityElement]::Escape([string]$stage.reason)
            [void]$xml.AppendLine("    <skipped message=`"$reason`" />")
        }
        [void]$xml.AppendLine('  </testcase>')
    }
    [void]$xml.AppendLine('</testsuite>')
    $junitPath = Join-Path $runDirectory 'test-results.junit.xml'
    [System.IO.File]::WriteAllText($junitPath, $xml.ToString(), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $resultsRoot 'latest.junit.xml'), $xml.ToString(),
        [System.Text.UTF8Encoding]::new($false))

    Write-Host ''
    Write-Host "harmony_agent MCP acceptance: PASSED=$passed FAILED=$failed SKIPPED=$skipped EXIT=$($script:ExitCode)"
    Write-Host "JSON: $jsonPath"
    Write-Host "JUnit: $junitPath"
}

function Stop-Fixture {
    if ($null -ne $script:FixtureProcess -and -not $script:FixtureProcess.HasExited) {
        Stop-Process -Id $script:FixtureProcess.Id -Force -ErrorAction SilentlyContinue
        $script:FixtureProcess.WaitForExit(5000) | Out-Null
    }
}

function Uninstall-TestApp {
    if ($script:InstalledBundle -and -not $KeepTestApp -and $null -ne $script:Hdc) {
        try {
            & $script:Hdc uninstall $script:BundleName 2>&1 | Out-Null
        } catch {
            Write-Warning "Unable to uninstall $($script:BundleName): $($_.Exception.Message)"
        }
    }
}

$script:StartedAt = Get-Date
Push-Location $projectRoot
try {
    try {
        Invoke-Stage -Name 'Preflight' -ConfigurationFailure -Action {
            $node = Get-Command node -ErrorAction SilentlyContinue
            if ($null -eq $node) { throw 'Node.js >=20 is required.' }
            $nodeVersionText = (& $node.Source --version).TrimStart('v')
            if ([version]$nodeVersionText -lt [version]'20.0.0') {
                throw "Node.js >=20 is required; found $nodeVersionText."
            }

            $script:SdkRoot = Find-SdkRoot
            if ($null -eq $script:SdkRoot) { throw 'HarmonyOS SDK API 26 was not found.' }
            $script:StudioRoot = Split-Path -Parent $script:SdkRoot
            $script:Hvigor = Join-Path $script:StudioRoot 'tools\hvigor\bin\hvigorw.bat'
            if (-not (Test-Path -LiteralPath $script:Hvigor -PathType Leaf)) {
                throw "Hvigor launcher was not found: $($script:Hvigor)"
            }
            if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'build-profile.json5'))) {
                throw 'Project build-profile.json5 is missing.'
            }
            Enable-RepositoryHooks

            if (-not [string]::IsNullOrWhiteSpace($HdcPath)) {
                $resolvedHdc = [System.IO.Path]::GetFullPath($HdcPath)
                if (-not (Test-Path -LiteralPath $resolvedHdc -PathType Leaf)) {
                    throw "Explicit HDC path does not exist: $resolvedHdc"
                }
                $script:Hdc = $resolvedHdc
            } else {
                $sdkHdc = Join-Path $script:SdkRoot 'default\openharmony\toolchains\hdc.exe'
                if (Test-Path -LiteralPath $sdkHdc -PathType Leaf) { $script:Hdc = $sdkHdc }
                else {
                    $hdcCommand = Get-Command hdc -ErrorAction SilentlyContinue
                    if ($null -ne $hdcCommand) { $script:Hdc = $hdcCommand.Source }
                }
            }

            if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'oh_modules'))) {
                if (-not $InstallDependencies) {
                    throw 'Project dependencies are missing. Re-run with -InstallDependencies to authorize OHPM download.'
                }
                $ohpm = Join-Path $script:StudioRoot 'tools\ohpm\bin\ohpm.bat'
                if (-not (Test-Path -LiteralPath $ohpm -PathType Leaf)) { throw 'OHPM was not found.' }
                Invoke-LoggedProcess -FilePath $ohpm -Arguments @('install', '--all') -LogName 'ohpm-install.log' | Out-Null
            } elseif ($InstallDependencies) {
                $ohpm = Join-Path $script:StudioRoot 'tools\ohpm\bin\ohpm.bat'
                if (-not (Test-Path -LiteralPath $ohpm -PathType Leaf)) { throw 'OHPM was not found.' }
                Invoke-LoggedProcess -FilePath $ohpm -Arguments @('install', '--all') -LogName 'ohpm-install.log' | Out-Null
            }
        }

        Invoke-Stage -Name 'ArkTS unit tests' -Action {
            Invoke-Hvigor -Arguments @('--mode', 'module', '-p', 'module=mcp_client@default', '-p', 'product=default',
                'test', '--no-daemon') -LogName 'arkts-unit-tests.log'
            $resultFile = Join-Path $projectRoot 'mcp_client\.test\default\intermediates\test\coverage_data\test_result.txt'
            if (-not (Test-Path -LiteralPath $resultFile)) { throw 'Hypium result file was not produced.' }
            $resultText = Get-Content -LiteralPath $resultFile -Raw
            if ($resultText -notmatch 'Failure:\s*0, Error:\s*0') {
                throw 'Hypium reported a failing or errored test. See arkts-unit-tests.log.'
            }
        }

        Invoke-Stage -Name 'Start fixture server' -Action {
            $fixtureScript = Join-Path $projectRoot 'tools\fixture\fixture-server.mjs'
            $readyFile = Join-Path $runDirectory 'fixture-ready.json'
            $stdoutFile = Join-Path $logsDirectory 'fixture.stdout.log'
            $stderrFile = Join-Path $logsDirectory 'fixture.stderr.log'
            $node = (Get-Command node -ErrorAction Stop).Source
            if ($Device -ne 'Skip' -and $null -ne $script:Hdc) {
                $targetsText = (& $script:Hdc list targets 2>&1 | Out-String).Trim()
                if ($LASTEXITCODE -eq 0) {
                    $script:DeviceTargets = @($targetsText -split '\r?\n' | Where-Object {
                        $_.Trim().Length -gt 0 -and $_ -notmatch '^\[Empty\]$'
                    })
                } else {
                    $script:HdcProbeReason = 'HDC could not enumerate targets.'
                }
            }
            $deviceCanReachFixture = $script:DeviceTargets.Count -gt 0 -and
                -not [string]::IsNullOrWhiteSpace($AdvertiseHost)
            $bindHost = if ($deviceCanReachFixture) { '0.0.0.0' } else { '127.0.0.1' }
            $arguments = @(
                "`"$fixtureScript`"", '--host', $bindHost, '--port', '0',
                '--ready-file', "`"$readyFile`""
            )
            $script:FixtureProcess = Start-Process -FilePath $node -ArgumentList $arguments -PassThru `
                -WindowStyle Hidden -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
            $deadline = (Get-Date).AddSeconds(10)
            while (-not (Test-Path -LiteralPath $readyFile)) {
                if ($script:FixtureProcess.HasExited) {
                    throw "Fixture server exited early. See $stderrFile"
                }
                if ((Get-Date) -ge $deadline) { throw 'Fixture server did not become ready within 10 seconds.' }
                Start-Sleep -Milliseconds 100
            }
            $script:FixtureInfo = Get-Content -LiteralPath $readyFile -Raw | ConvertFrom-Json
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$($script:FixtureInfo.port)/health" -TimeoutSec 5
            if ($health.ready -ne $true) { throw 'Fixture health check failed.' }
        }

        Invoke-Stage -Name 'Fixture protocol contracts' -Action {
            $contract = Join-Path $projectRoot 'tools\fixture\fixture-contract.test.mjs'
            $fixtureUrl = "http://127.0.0.1:$($script:FixtureInfo.port)"
            Invoke-LoggedProcess -FilePath (Get-Command node -ErrorAction Stop).Source `
                -Arguments @('--test', $contract) -LogName 'fixture-contracts.log' -Environment @{
                    MCP_FIXTURE_URL = $fixtureUrl
                    MCP_PROTOCOL = $Protocol
                } | Out-Null
        }

        Invoke-Stage -Name 'Release HAR build' -Action {
            Invoke-Hvigor -Arguments @('--mode', 'module', '-p', 'module=mcp_client@default', '-p', 'product=default',
                '-p', 'buildMode=release', 'assembleHar', '--no-daemon') -LogName 'release-har-build.log'
            $har = Join-Path $projectRoot 'mcp_client\build\default\outputs\default\mcp_client.har'
            if (-not (Test-Path -LiteralPath $har -PathType Leaf)) { throw 'Release HAR output was not produced.' }
            Copy-Item -LiteralPath $har -Destination (Join-Path $deliverablesDirectory 'harmony_agent-mcp-client-0.1.0.har')
        }

        Invoke-Stage -Name 'HAR runtime dependency audit' -Action {
            $har = Join-Path $deliverablesDirectory 'harmony_agent-mcp-client-0.1.0.har'
            Add-Type -AssemblyName System.Formats.Tar
            $fileStream = [System.IO.File]::OpenRead($har)
            $gzipStream = [System.IO.Compression.GZipStream]::new(
                $fileStream, [System.IO.Compression.CompressionMode]::Decompress)
            $archive = [System.Formats.Tar.TarReader]::new($gzipStream)
            try {
                $forbidden = [System.Collections.Generic.List[string]]::new()
                while ($null -ne ($entry = $archive.GetNextEntry())) {
                    if ($entry.Name -match '(^|/)(node_modules|cross-spawn|stdio|process|buffer)(/|$)') {
                        $forbidden.Add($entry.Name)
                    }
                }
                if ($forbidden.Count -gt 0) {
                    throw "HAR contains forbidden Node runtime entries: $($forbidden -join ', ')"
                }
            } finally {
                $archive.Dispose()
                $gzipStream.Dispose()
                $fileStream.Dispose()
            }
            $sourceRoot = Join-Path $projectRoot 'mcp_client\src\main'
            $sourceMatches = @(& rg -n '(node:|from [''\"](fs|child_process|stream|buffer)[''\"]|\bprocess\.|\bBuffer\b|stdio)' `
                $sourceRoot 2>$null)
            if ($LASTEXITCODE -eq 0 -and $sourceMatches.Count -gt 0) {
                throw "HAR source references a forbidden Node runtime API: $($sourceMatches -join '; ')"
            }
            if ($LASTEXITCODE -gt 1) { throw 'rg failed during HAR source audit.' }
        }

        $deviceSigningNeeded = $Device -ne 'Skip' -and $null -ne $script:Hdc -and
            $null -eq $script:HdcProbeReason -and $script:DeviceTargets.Count -gt 0 -and
            -not [string]::IsNullOrWhiteSpace($AdvertiseHost)
        if ($deviceSigningNeeded) {
            Invoke-Stage -Name 'Prepare device signing' -ConfigurationFailure -Action {
                Prepare-DeviceSigning
            }
        }

        Invoke-Stage -Name 'Debug test host builds' -Action {
            try {
                Invoke-Hvigor -Arguments @('--mode', 'module', '-p', 'module=test_host@default', '-p', 'product=default',
                    '-p', 'buildMode=debug', 'assembleHap', '--no-daemon') -LogName 'debug-test-host-build.log'
                Invoke-Hvigor -Arguments @('--mode', 'module', '-p', 'module=test_host@ohosTest', '-p', 'product=default',
                    '-p', 'buildMode=debug', 'assembleHap', '--no-daemon') -LogName 'debug-ohos-test-build.log'
                $mainHap = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'test_host\build') -Recurse -File `
                    -Filter '*default*.hap' | Where-Object FullName -notmatch 'ohosTest' | Select-Object -First 1
                $testHap = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'test_host\build') -Recurse -File `
                    -Filter '*.hap' | Where-Object FullName -match '[\\/]outputs[\\/]ohosTest[\\/]' | Select-Object -First 1
                if ($null -eq $mainHap) { throw 'Debug test host HAP output was not produced.' }
                if ($null -eq $testHap) { throw 'ohosTest HAP output was not produced.' }
                Copy-Item -LiteralPath $mainHap.FullName -Destination (Join-Path $deliverablesDirectory $mainHap.Name)
                Copy-Item -LiteralPath $testHap.FullName -Destination (Join-Path $deliverablesDirectory $testHap.Name)
            } finally {
                if ($script:SigningPrepared -or -not $script:BuildProfileRestored) {
                    Restore-BuildProfile
                }
            }
        }

        if ($Device -eq 'Skip') {
            Add-SkippedStage -Name 'Device integration tests' -Reason 'Disabled by -Device Skip.'
        } elseif ($null -eq $script:Hdc) {
            if ($Device -eq 'Required') {
                $script:ExitCode = 2
                throw 'HDC is required but was not found. Use -HdcPath to provide it.'
            }
            Add-SkippedStage -Name 'Device integration tests' -Reason 'HDC was not found; host tests completed.'
        } elseif ($null -ne $script:HdcProbeReason) {
            if ($Device -eq 'Required') {
                $script:ExitCode = 2
                throw $script:HdcProbeReason
            }
            Add-SkippedStage -Name 'Device integration tests' `
                -Reason "$($script:HdcProbeReason) Host tests completed."
        } else {
            if ($script:DeviceTargets.Count -eq 0) {
                if ($Device -eq 'Required') {
                    $script:ExitCode = 1
                    throw 'No HarmonyOS device or emulator is connected.'
                }
                Add-SkippedStage -Name 'Device integration tests' -Reason 'No device or emulator detected; host tests completed.'
            } elseif ([string]::IsNullOrWhiteSpace($AdvertiseHost)) {
                if ($Device -eq 'Required') {
                    $script:ExitCode = 2
                    throw '-AdvertiseHost is required when device tests are mandatory.'
                }
                Add-SkippedStage -Name 'Device integration tests' `
                    -Reason 'A device was detected, but -AdvertiseHost was not supplied; no network or firewall settings were changed.'
            } else {
                Invoke-Stage -Name 'Device integration tests' -Action {
                    $mainHap = Get-ChildItem -LiteralPath $deliverablesDirectory -File -Filter '*default*.hap' |
                        Where-Object Name -notmatch 'ohosTest|test_host_test' | Select-Object -First 1
                    $testHap = Get-ChildItem -LiteralPath $deliverablesDirectory -File -Filter '*.hap' |
                        Where-Object Name -match 'ohosTest|test_host_test' | Select-Object -First 1
                    if ($null -eq $mainHap -or $null -eq $testHap) {
                        throw 'Installable main/test HAP pair was not found.'
                    }
                    Invoke-LoggedProcess -FilePath $script:Hdc -Arguments @('install', '-r', $mainHap.FullName) `
                        -LogName 'device-install-main.log' | Out-Null
                    $script:InstalledBundle = $true
                    Invoke-LoggedProcess -FilePath $script:Hdc -Arguments @('install', '-r', $testHap.FullName) `
                        -LogName 'device-install-test.log' | Out-Null
                    $fixtureUrl = "http://$AdvertiseHost`:$($script:FixtureInfo.port)"
                    $output = Invoke-LoggedProcess -FilePath $script:Hdc -Arguments @(
                        'shell', 'aa', 'test', '-b', $script:BundleName, '-m', 'test_host_test',
                        '-s', 'unittest', 'OpenHarmonyTestRunner', '-s', 'fixtureUrl', $fixtureUrl,
                        '-s', 'timeout', '60000'
                    ) -LogName 'device-tests.log'
                    if ($output -match 'Failure:\s*[1-9]' -or $output -match 'Error:\s*[1-9]') {
                        throw 'Device Hypium tests reported failures.'
                    }
                }
            }
        }
    } catch {
        if ($script:ExitCode -eq 0) { $script:ExitCode = 1 }
        Write-Warning (Protect-Text $_.Exception.Message)
    }
} finally {
    Uninstall-TestApp
    Stop-Fixture
    if (-not $script:BuildProfileRestored) {
        try {
            Restore-BuildProfile
        } catch {
            if ($script:ExitCode -eq 0) { $script:ExitCode = 1 }
            Add-Stage -Name 'Restore signing template' -Status FAILED -DurationMs 0 `
                -Reason $_.Exception.Message
            Write-Warning (Protect-Text $_.Exception.Message)
        }
    }
    Write-Reports
    Pop-Location
}

exit $script:ExitCode
