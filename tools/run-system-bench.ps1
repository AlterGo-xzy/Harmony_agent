[CmdletBinding()]
param(
    [ValidateSet('Fixture', 'Live')]
    [string]$Mode = 'Fixture',

    [string]$OutputDirectory = '',

    [switch]$AllowProviderBatch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$workspace = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$artifactsRoot = Join-Path $workspace 'artifacts'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $artifactsRoot "t43-system-bench-live\$stamp-$($Mode.ToLowerInvariant())"
} elseif (-not [IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $workspace $OutputDirectory
}
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$allowedPrefix = [IO.Path]::GetFullPath($artifactsRoot) + [IO.Path]::DirectorySeparatorChar
if (-not $outputRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputDirectory must be a new directory below $artifactsRoot."
}
if (Test-Path -LiteralPath $outputRoot) {
    throw "OutputDirectory already exists: $outputRoot"
}
if ($Mode -eq 'Live' -and -not $AllowProviderBatch) {
    throw 'Live mode requires -AllowProviderBatch.'
}

$gatewayBaseUrl = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_BASE_URL', 'Process')
$gatewayToken = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', 'Process')
if ($Mode -eq 'Live' -and
    ([string]::IsNullOrWhiteSpace($gatewayBaseUrl) -or [string]::IsNullOrWhiteSpace($gatewayToken))) {
    throw 'Live mode must be launched as a child of aigw run.'
}

$sourceCommit = (& git -C $workspace rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'A full source commit is required before the benchmark can run.'
}
$rootBuildHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $workspace 'build-profile.json5')).Hash

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$logs = Join-Path $outputRoot 'logs'
$isolated = Join-Path $outputRoot 'isolated-project'
New-Item -ItemType Directory -Path $logs, $isolated -Force | Out-Null

function Write-JsonNoBom {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Value)
    $json = $Value | ConvertTo-Json -Depth 20
    [IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}

function Wait-ReadyFile {
    param(
        [Parameter(Mandatory = $true)][Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind
    )
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not (Test-Path -LiteralPath $Path)) {
        $Process.Refresh()
        if ($Process.HasExited) { throw "$Kind exited before becoming ready." }
        if ([DateTime]::UtcNow -ge $deadline) { throw "$Kind did not become ready within 15 seconds." }
        Start-Sleep -Milliseconds 100
    }
}

function Stop-OwnedProcess {
    param([Diagnostics.Process]$Process)
    if ($null -eq $Process) { return }
    $Process.Refresh()
    if (-not $Process.HasExited) {
        Stop-Process -Id $Process.Id -Force
        $Process.WaitForExit(5000) | Out-Null
    }
}

function Copy-ModuleSource {
    param([Parameter(Mandatory = $true)][string]$Name)
    $source = Join-Path $workspace $Name
    $destination = Join-Path $isolated $Name
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Get-ChildItem -LiteralPath $source -File | Copy-Item -Destination $destination
    Copy-Item -LiteralPath (Join-Path $source 'src') -Destination $destination -Recurse
}

function Add-ModuleDependencyCopy {
    param(
        [Parameter(Mandatory = $true)][string]$Consumer,
        [Parameter(Mandatory = $true)][string]$PackageName,
        [Parameter(Mandatory = $true)][string]$SourceModule
    )
    $scope = Join-Path $isolated "$Consumer\oh_modules\@harmony_agent"
    New-Item -ItemType Directory -Path $scope -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $isolated $SourceModule) -Destination (Join-Path $scope $PackageName) -Recurse
}

$node = (Get-Command node -ErrorAction Stop).Source
$gatewayProcess = $null
$fixtureProcess = $null
$gatewayReady = Join-Path $outputRoot 'gateway-ready.json'
$gatewaySummary = Join-Path $outputRoot 'gateway-bridge-summary.json'
$fixtureReady = Join-Path $outputRoot 'mcp-fixture-ready.json'
$providerRequests = 0
$reportWritten = $false
$gatewayKind = if ($Mode -eq 'Live') { 'live-bridge' } else { 'fixture-gateway' }

try {
    if ($Mode -eq 'Live') {
        $configPath = Join-Path $env:LOCALAPPDATA 'LocalAIGateway\config.json'
        $configHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $configPath).Hash
        if ($configHash -ne '3E3FE8EE7F9E170C809E263B3191A28426C8DC9E41538AA27B820D5442DA9E95') {
            throw 'Local AI Gateway config hash drifted from the authorized revision-13 snapshot.'
        }
        $aigw = (Get-Command aigw -ErrorAction Stop).Source
        $validateText = (& $aigw config validate --json 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'aigw config validate failed.' }
        $profileText = (& $aigw profile list --json 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'aigw profile list failed.' }
        if ($validateText -notmatch '"valid"\s*:\s*true' -or $validateText -notmatch '"revision"\s*:\s*13') {
            throw 'Live gateway configuration is not valid revision 13.'
        }
        if ($profileText -notmatch '"id"\s*:\s*"deepseek"' -or
            $profileText -notmatch '"active"\s*:\s*true' -or
            $profileText -notmatch '"complete"\s*:\s*true') {
            throw 'The deepseek profile is not active and complete.'
        }
        Write-JsonNoBom -Path (Join-Path $outputRoot 'live-preflight.json') -Value ([ordered]@{
            configurationValid = $true
            configurationRevision = 13
            configSha256 = $configHash
            activeProfileId = 'deepseek'
            activeProfileComplete = $true
            providerId = 'official'
            endpoint = 'https://api.deepseek.com'
            modelAlias = 'aigw/default'
            upstreamModel = 'deepseek-flash'
            executionAuthorizationRef = 'user-approved-2026-10-17-max39-usd0.43134'
            credentialsRead = $false
        })
        $gatewayProcess = Start-Process -FilePath $node -ArgumentList @(
            "`"$(Join-Path $workspace 'tools\gateway-device-bridge.mjs')`"",
            '--ready-file', "`"$gatewayReady`"",
            '--summary-file', "`"$gatewaySummary`""
        ) -PassThru -WindowStyle Hidden -WorkingDirectory $workspace `
            -RedirectStandardOutput (Join-Path $logs 'gateway.stdout.log') `
            -RedirectStandardError (Join-Path $logs 'gateway.stderr.log')
    } else {
        $gatewayProcess = Start-Process -FilePath $node -ArgumentList @(
            "`"$(Join-Path $workspace 'tools\system-bench\fake-gateway-server.mjs')`"",
            '--ready-file', "`"$gatewayReady`""
        ) -PassThru -WindowStyle Hidden -WorkingDirectory $workspace `
            -RedirectStandardOutput (Join-Path $logs 'gateway.stdout.log') `
            -RedirectStandardError (Join-Path $logs 'gateway.stderr.log')
    }
    Wait-ReadyFile -Process $gatewayProcess -Path $gatewayReady -Kind $gatewayKind
    $gatewayPort = [int](Get-Content -Raw -LiteralPath $gatewayReady | ConvertFrom-Json).port

    $fixtureProcess = Start-Process -FilePath $node -ArgumentList @(
        "`"$(Join-Path $workspace 'tools\fixture\fixture-server.mjs')`"",
        '--host', '127.0.0.1', '--port', '0', '--ready-file', "`"$fixtureReady`""
    ) -PassThru -WindowStyle Hidden -WorkingDirectory $workspace `
        -RedirectStandardOutput (Join-Path $logs 'mcp.stdout.log') `
        -RedirectStandardError (Join-Path $logs 'mcp.stderr.log')
    Wait-ReadyFile -Process $fixtureProcess -Path $fixtureReady -Kind 'MCP fixture server'
    $mcpPort = [int](Get-Content -Raw -LiteralPath $fixtureReady | ConvertFrom-Json).port

    Copy-Item -LiteralPath (Join-Path $workspace 'AppScope') -Destination $isolated -Recurse
    Copy-Item -LiteralPath (Join-Path $workspace 'hvigor') -Destination $isolated -Recurse
    Copy-Item -LiteralPath (Join-Path $workspace 'hvigorfile.ts') -Destination $isolated
    Copy-Item -LiteralPath (Join-Path $workspace 'oh-package.json5') -Destination $isolated
    Copy-Item -LiteralPath (Join-Path $workspace 'oh_modules') -Destination $isolated -Recurse
    foreach ($module in @('agent_contracts', 'agent_core', 'agent_runtime', 'mcp_client', 'agent_connectors', 'agent_testkit')) {
        Copy-ModuleSource -Name $module
    }

    Add-ModuleDependencyCopy -Consumer 'agent_core' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
    Add-ModuleDependencyCopy -Consumer 'agent_runtime' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
    Add-ModuleDependencyCopy -Consumer 'agent_runtime' -PackageName 'agent-core' -SourceModule 'agent_core'
    Add-ModuleDependencyCopy -Consumer 'agent_testkit' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
    Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
    Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'agent-runtime' -SourceModule 'agent_runtime'
    Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'mcp-client' -SourceModule 'mcp_client'
    Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'agent-testkit' -SourceModule 'agent_testkit'

    $connectorManifest = [ordered]@{
        name = '@harmony_agent/agent-connectors'
        version = '0.8.0'
        description = 'Headless MCP adapters for the harmony_agent runtime'
        main = 'Index.ets'
        author = 'harmony_agent'
        license = 'Apache-2.0'
        dependencies = [ordered]@{
            '@harmony_agent/agent-contracts' = 'file:../agent_contracts'
            '@harmony_agent/agent-runtime' = 'file:../agent_runtime'
            '@harmony_agent/mcp-client' = 'file:../mcp_client'
            '@harmony_agent/agent-testkit' = 'file:../agent_testkit'
        }
    }
    Write-JsonNoBom -Path (Join-Path $isolated 'agent_connectors\oh-package.json5') -Value $connectorManifest
    Copy-Item -LiteralPath (Join-Path $workspace 'tools\system-bench\SystemBenchmarkLive.test.ets') `
        -Destination (Join-Path $isolated 'agent_connectors\src\test\SystemBenchmarkLive.test.ets')
    [IO.File]::WriteAllText((Join-Path $isolated 'agent_connectors\src\test\List.test.ets'), @'
import systemBenchmarkLiveTest from './SystemBenchmarkLive.test';

export default function testsuite(): void {
  systemBenchmarkLiveTest();
}
'@, [Text.UTF8Encoding]::new($false))
    $profileIdentity = 'deepseek|active|complete|official|https://api.deepseek.com|aigw/default|deepseek-flash|revision:13'
    $profileDigest = 'sha256:' + [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($profileIdentity))).ToLowerInvariant()
    $executionId = "harmony-agent-system-bench-$stamp-$($Mode.ToLowerInvariant())"
    $authorizationRef = if ($Mode -eq 'Live') {
        'user-approved-2026-10-17-max39-usd0.43134'
    } else {
        'fixture-verification-no-provider'
    }
    $liveLiteral = if ($Mode -eq 'Live') { 'true' } else { 'false' }
    $configSource = @"
export const BENCH_GATEWAY_PORT: number = $gatewayPort;
export const BENCH_MCP_PORT: number = $mcpPort;
export const BENCH_OS_VERSION: string = 'Windows-host-previewer';
export const BENCH_DEVICE_CLASS: string = 'x64-host-previewer';
export const BENCH_SOURCE_COMMIT: string = '$sourceCommit';
export const BENCH_EXECUTION_ID: string = '$executionId';
export const BENCH_PROFILE_DIGEST: string = '$profileDigest';
export const BENCH_AUTHORIZATION_REF: string = '$authorizationRef';
export const BENCH_LIVE: boolean = $liveLiteral;
"@
    [IO.File]::WriteAllText((Join-Path $isolated 'agent_connectors\src\test\SystemBenchmarkLiveConfig.ets'),
        $configSource, [Text.UTF8Encoding]::new($false))

    $isolatedBuild = [ordered]@{
        app = [ordered]@{
            signingConfigs = @()
            products = @([ordered]@{
                name = 'default'
                targetSdkVersion = '26.0.0'
                compatibleSdkVersion = '26.0.0'
                runtimeOS = 'HarmonyOS'
                buildOption = [ordered]@{ strictMode = [ordered]@{
                    caseSensitiveCheck = $true
                    useNormalizedOHMUrl = $true
                }}
            })
            buildModeSet = @([ordered]@{ name = 'debug' }, [ordered]@{ name = 'release' })
        }
        modules = @()
    }
    foreach ($module in @('agent_contracts', 'agent_core', 'agent_runtime', 'mcp_client', 'agent_connectors', 'agent_testkit')) {
        $isolatedBuild.modules += [ordered]@{
            name = $module
            srcPath = "./$module"
            targets = @([ordered]@{ name = 'default'; applyToProducts = @('default') })
        }
    }
    Write-JsonNoBom -Path (Join-Path $isolated 'build-profile.json5') -Value $isolatedBuild

    $hvigor = 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
    $env:DEVECO_SDK_HOME = 'D:\DevEco\DevEco Studio\sdk'
    $testLog = Join-Path $logs 'hvigor-test.log'
    Push-Location $isolated
    try {
        & $hvigor --mode module -p module=agent_connectors@default -p product=default test --no-daemon 2>&1 |
            Tee-Object -FilePath $testLog
        $testExit = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    if ($testExit -ne 0) { throw "System Bench harness failed with exit code $testExit." }
    $resultPath = Join-Path $isolated 'agent_connectors\.test\default\intermediates\test\coverage_data\test_result.txt'
    if (-not (Test-Path -LiteralPath $resultPath)) { throw 'Hypium result file was not produced.' }
    Copy-Item -LiteralPath $resultPath -Destination (Join-Path $outputRoot 'test_result.txt')
    $resultText = Get-Content -Raw -LiteralPath $resultPath
    if ($resultText -notmatch 'Failure:\s*0' -or $resultText -notmatch 'Error:\s*0' -or
        $resultText -notmatch 'Pass:\s*1') {
        throw 'System Bench Hypium result did not report 1/1 pass.'
    }
    $coverageLog = Join-Path $isolated 'agent_connectors\.test\default\intermediates\test\coverage_data\coverage.log'
    if (-not (Test-Path -LiteralPath $coverageLog)) { throw 'Hypium coverage log was not produced.' }
    Copy-Item -LiteralPath $coverageLog -Destination (Join-Path $logs 'coverage.log')
    $logText = Get-Content -Raw -LiteralPath $coverageLog
    $chunkMatches = @([regex]::Matches($logText, 'HARMONY_AGENT_BENCH_RUN_CHUNK=(\d+)/(\d+):([^\r\n]*)'))
    if ($chunkMatches.Count -eq 0) { throw 'The sealed benchmark report chunks were not found in the test log.' }
    $declaredChunkCount = [int]$chunkMatches[0].Groups[2].Value
    if ($chunkMatches.Count -ne $declaredChunkCount) {
        throw "The sealed benchmark report is incomplete: found $($chunkMatches.Count) of $declaredChunkCount chunks."
    }
    $orderedChunks = @($chunkMatches | Sort-Object { [int]$_.Groups[1].Value })
    $reportJson = [string]::Concat(@($orderedChunks | ForEach-Object { $_.Groups[3].Value }))
    $run = $reportJson | ConvertFrom-Json -Depth 30
    if ($run.records.Count -ne 24) { throw 'The sealed benchmark report does not contain 24 records.' }
    $providerRequests = 0
    $costMicros = 0
    foreach ($record in $run.records) {
        $providerRequests += [int]$record.evidence.providerRequestCount
        $costMicros += [int]$record.sample.monetaryCostMicros
    }
    if ($providerRequests -gt 39) { throw "Provider request limit exceeded: $providerRequests" }
    if ($costMicros -gt 431340) { throw "Monetary limit exceeded: $costMicros" }
    if ($Mode -eq 'Live') {
        Write-JsonNoBom -Path (Join-Path $outputRoot 'system-bench-run.json') -Value $run
        $reportWritten = $true
    }
    Write-JsonNoBom -Path (Join-Path $outputRoot 'summary.json') -Value ([ordered]@{
        task = 'T43'
        mode = $Mode
        sourceCommit = $sourceCommit
        executionId = $executionId
        records = 24
        providerRequests = $providerRequests
        providerRequestLimit = 39
        monetaryCostMicros = $costMicros
        monetaryCostLimitMicros = 431340
        reportPersisted = $reportWritten
        rootBuildProfileSha256 = $rootBuildHash
        credentialsRecorded = $false
    })
} finally {
    Stop-OwnedProcess -Process $fixtureProcess
    Stop-OwnedProcess -Process $gatewayProcess
    $rootBuildHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath `
        (Join-Path $workspace 'build-profile.json5')).Hash
    if ($rootBuildHashAfter -ne $rootBuildHash) {
        throw 'Root build-profile.json5 changed during benchmark execution.'
    }
}

Write-Output "SYSTEM_BENCH_MODE=$Mode"
Write-Output "SYSTEM_BENCH_OUTPUT=$outputRoot"
Write-Output "SYSTEM_BENCH_PROVIDER_REQUESTS=$providerRequests"
Write-Output "SYSTEM_BENCH_REPORT_WRITTEN=$reportWritten"
