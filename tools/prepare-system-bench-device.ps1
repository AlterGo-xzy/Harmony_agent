[CmdletBinding()]
param(
    [ValidateRange(1, 65535)]
    [int]$GatewayDevicePort = 4014,

    [string]$OutputDirectory = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$workspace = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$artifactsRoot = Join-Path $workspace 'artifacts'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $artifactsRoot "t43-system-bench-live\$stamp-device-unsigned-build"
} elseif (-not [IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $workspace $OutputDirectory
}
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$allowedPrefix = [IO.Path]::GetFullPath($artifactsRoot) + [IO.Path]::DirectorySeparatorChar
if (-not $outputRoot.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputDirectory must be a new directory below $artifactsRoot."
}
if (Test-Path -LiteralPath $outputRoot) { throw "OutputDirectory already exists: $outputRoot" }

$sourceCommit = (& git -C $workspace rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[0-9a-f]{40}$') {
    throw 'A full source commit is required before the device package can be prepared.'
}
$rootBuildHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $workspace 'build-profile.json5')).Hash
if ($rootBuildHash -ne 'B70064EB7D6DC236430958498C8B10EDD4C2E605C14713B6F82B4545FD4AC21D') {
    throw 'Root build-profile.json5 drifted before device package preparation.'
}

$isolated = Join-Path $outputRoot 'isolated-project'
$deliverables = Join-Path $outputRoot 'deliverables'
$logs = Join-Path $outputRoot 'logs'
New-Item -ItemType Directory -Path $isolated, $deliverables, $logs -Force | Out-Null

function Write-JsonNoBom {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Value)
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 20) + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false))
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

Copy-Item -LiteralPath (Join-Path $workspace 'AppScope') -Destination $isolated -Recurse
Copy-Item -LiteralPath (Join-Path $workspace 'hvigor') -Destination $isolated -Recurse
Copy-Item -LiteralPath (Join-Path $workspace 'hvigorfile.ts') -Destination $isolated
Copy-Item -LiteralPath (Join-Path $workspace 'oh-package.json5') -Destination $isolated
Copy-Item -LiteralPath (Join-Path $workspace 'oh_modules') -Destination $isolated -Recurse

$modules = @('agent_contracts', 'agent_core', 'agent_runtime', 'mcp_client', 'agent_connectors', 'agent_testkit', 'test_host')
foreach ($module in $modules) { Copy-ModuleSource -Name $module }

Add-ModuleDependencyCopy -Consumer 'agent_core' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
Add-ModuleDependencyCopy -Consumer 'agent_runtime' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
Add-ModuleDependencyCopy -Consumer 'agent_runtime' -PackageName 'agent-core' -SourceModule 'agent_core'
Add-ModuleDependencyCopy -Consumer 'agent_testkit' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'agent-runtime' -SourceModule 'agent_runtime'
Add-ModuleDependencyCopy -Consumer 'agent_connectors' -PackageName 'mcp-client' -SourceModule 'mcp_client'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'agent-contracts' -SourceModule 'agent_contracts'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'agent-core' -SourceModule 'agent_core'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'agent-runtime' -SourceModule 'agent_runtime'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'mcp-client' -SourceModule 'mcp_client'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'agent-connectors' -SourceModule 'agent_connectors'
Add-ModuleDependencyCopy -Consumer 'test_host' -PackageName 'agent-testkit' -SourceModule 'agent_testkit'

$hostManifest = [ordered]@{
    name = 'test_host'
    version = '0.1.0'
    description = 'Headless device test host for harmony_agent Agent HAR modules'
    main = ''
    author = 'harmony_agent'
    license = 'Apache-2.0'
    dependencies = [ordered]@{
        '@harmony_agent/mcp-client' = 'file:../mcp_client'
        '@harmony_agent/agent-contracts' = 'file:../agent_contracts'
        '@harmony_agent/agent-core' = 'file:../agent_core'
        '@harmony_agent/agent-runtime' = 'file:../agent_runtime'
        '@harmony_agent/agent-connectors' = 'file:../agent_connectors'
        '@harmony_agent/agent-testkit' = 'file:../agent_testkit'
    }
}
Write-JsonNoBom -Path (Join-Path $isolated 'test_host\oh-package.json5') -Value $hostManifest

$deviceTestDirectory = Join-Path $isolated 'test_host\src\ohosTest\ets\test'
$harness = Get-Content -Raw -LiteralPath (Join-Path $workspace 'tools\system-bench\SystemBenchmarkLive.test.ets')
$harness = $harness.Replace("from '../../Index';", "from '@harmony_agent/agent-connectors';")
[IO.File]::WriteAllText((Join-Path $deviceTestDirectory 'SystemBenchmarkLiveDevice.test.ets'), $harness,
    [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $deviceTestDirectory 'List.test.ets'), @'
import systemBenchmarkLiveDeviceTest from './SystemBenchmarkLiveDevice.test';

export default function testsuite(): void {
  systemBenchmarkLiveDeviceTest();
}
'@, [Text.UTF8Encoding]::new($false))

$profileIdentity = 'deepseek|active|complete|official|https://api.deepseek.com|aigw/default|deepseek-flash|revision:13'
$profileDigest = 'sha256:' + [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($profileIdentity))).ToLowerInvariant()
$executionId = "harmony-agent-system-bench-$stamp-device"
$configSource = @"
export const BENCH_GATEWAY_PORT: number = $GatewayDevicePort;
export const BENCH_MCP_PORT: number = 1;
export const BENCH_SOURCE_COMMIT: string = '$sourceCommit';
export const BENCH_EXECUTION_ID: string = '$executionId';
export const BENCH_PROFILE_DIGEST: string = '$profileDigest';
export const BENCH_AUTHORIZATION_REF: string = 'user-approved-2026-10-17-max39-usd0.43134';
export const BENCH_LIVE: boolean = true;
"@
[IO.File]::WriteAllText((Join-Path $deviceTestDirectory 'SystemBenchmarkLiveConfig.ets'), $configSource,
    [Text.UTF8Encoding]::new($false))

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
foreach ($module in $modules) {
    $isolatedBuild.modules += [ordered]@{
        name = $module
        srcPath = "./$module"
        targets = @([ordered]@{ name = 'default'; applyToProducts = @('default') })
    }
}
Write-JsonNoBom -Path (Join-Path $isolated 'build-profile.json5') -Value $isolatedBuild

$hvigor = 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
$env:DEVECO_SDK_HOME = 'D:\DevEco\DevEco Studio\sdk'
Push-Location $isolated
try {
    & $hvigor --mode module -p module=test_host@default -p product=default -p buildMode=debug assembleHap --no-daemon `
        2>&1 | Tee-Object -FilePath (Join-Path $logs 'main-hap-build.log')
    if ($LASTEXITCODE -ne 0) { throw 'Unsigned main HAP build failed.' }
    & $hvigor --mode module -p module=test_host@ohosTest -p product=default -p buildMode=debug assembleHap --no-daemon `
        2>&1 | Tee-Object -FilePath (Join-Path $logs 'test-hap-build.log')
    if ($LASTEXITCODE -ne 0) { throw 'Unsigned ohosTest HAP build failed.' }
} finally {
    Pop-Location
}

$mainHap = Get-ChildItem -LiteralPath (Join-Path $isolated 'test_host\build\default\outputs\default') -File `
    -Filter '*-unsigned.hap' | Select-Object -First 1
$testHap = Get-ChildItem -LiteralPath (Join-Path $isolated 'test_host\build\default\outputs\ohosTest') -File `
    -Filter '*-unsigned.hap' | Select-Object -First 1
if ($null -eq $mainHap -or $null -eq $testHap) { throw 'Both unsigned device HAP outputs are required.' }
$mainOutput = Join-Path $deliverables 'harmony-agent-system-bench-main-unsigned.hap'
$testOutput = Join-Path $deliverables 'harmony-agent-system-bench-test-unsigned.hap'
Copy-Item -LiteralPath $mainHap.FullName -Destination $mainOutput
Copy-Item -LiteralPath $testHap.FullName -Destination $testOutput

Write-JsonNoBom -Path (Join-Path $outputRoot 'build-summary.json') -Value ([ordered]@{
    task = 'T43'
    sourceCommit = $sourceCommit
    executionId = $executionId
    bundleName = 'com.harmony.agent'
    testModule = 'test_host_test'
    testClass = 'SystemBenchmarkLive'
    gatewayDevicePort = $GatewayDevicePort
    signed = $false
    installed = $false
    deviceRun = $false
    mainHap = [ordered]@{ path = $mainOutput; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $mainOutput).Hash }
    testHap = [ordered]@{ path = $testOutput; sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $testOutput).Hash }
    rootBuildProfileSha256 = $rootBuildHash
    credentialsRecorded = $false
})

Write-Host "SYSTEM_BENCH_DEVICE_BUILD=$outputRoot"
