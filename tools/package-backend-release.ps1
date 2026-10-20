[CmdletBinding()]
param(
    [Alias('Version')]
    [string]$ReleaseVersion = '0.1.0-rc.2',
    [string]$OutputRoot = '.\artifacts\backend-release',
    [string]$SearchServiceRoot = 'D:\Shuvi-agent\services\search-mcp',
    [switch]$IncludeUnsignedReferenceHap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$resolvedOutputRoot = [IO.Path]::GetFullPath((Join-Path $workspaceRoot $OutputRoot)).TrimEnd('\')
if (-not $resolvedOutputRoot.StartsWith($workspaceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputRoot must stay inside the Harmony Agent workspace.'
}

$dirty = (& git -C $workspaceRoot status --porcelain) -join "`n"
if (-not [string]::IsNullOrWhiteSpace($dirty)) {
    throw 'Refusing to package a dirty worktree. Commit or revert source changes first.'
}

$sourceCommit = (& git -C $workspaceRoot rev-parse HEAD).Trim()
$sourceBranch = (& git -C $workspaceRoot branch --show-current).Trim()
$shortCommit = $sourceCommit.Substring(0, 8)
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$packageName = "harmony-agent-backend-sdk-$ReleaseVersion-$shortCommit"
$runDirectory = Join-Path $resolvedOutputRoot "$timestamp-$shortCommit"
$stageDirectory = Join-Path $runDirectory $packageName
$harDirectory = Join-Path $stageDirectory 'hars'
$docsDirectory = Join-Path $stageDirectory 'docs'
$verificationDirectory = Join-Path $stageDirectory 'verification'
$referenceDirectory = Join-Path $stageDirectory 'reference'
New-Item -ItemType Directory -Path $harDirectory, $docsDirectory, $verificationDirectory -Force | Out-Null

$moduleDefinitions = @(
    [pscustomobject]@{ Directory = 'agent_contracts'; Package = '@harmony_agent/agent-contracts'; Role = 'required' },
    [pscustomobject]@{ Directory = 'agent_core'; Package = '@harmony_agent/agent-core'; Role = 'required' },
    [pscustomobject]@{ Directory = 'agent_runtime'; Package = '@harmony_agent/agent-runtime'; Role = 'required' },
    [pscustomobject]@{ Directory = 'mcp_client'; Package = '@harmony_agent/mcp-client'; Role = 'required' },
    [pscustomobject]@{ Directory = 'agent_connectors'; Package = '@harmony_agent/agent-connectors'; Role = 'required' },
    [pscustomobject]@{ Directory = 'agent_storage'; Package = '@harmony_agent/agent-storage'; Role = 'production-host' },
    [pscustomobject]@{ Directory = 'native_tools'; Package = '@harmony_agent/native-tools'; Role = 'optional-native-capabilities' }
)

$manifestModules = @()
$packageVersions = @{}
foreach ($definition in $moduleDefinitions) {
    $sourceHar = Join-Path $workspaceRoot "$($definition.Directory)\build\default\outputs\default\$($definition.Directory).har"
    if (-not (Test-Path -LiteralPath $sourceHar)) {
        throw "Missing Release HAR: $sourceHar"
    }
    $metadataText = (& tar -xOf $sourceHar 'package/oh-package.json5') -join "`n"
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($metadataText)) {
        throw "HAR metadata is missing: $sourceHar"
    }
    $metadata = $metadataText | ConvertFrom-Json
    if ($metadata.name -ne $definition.Package -or $metadata.metadata.debug -ne $false -or
        [int]$metadata.compatibleSdkVersion -ne 26) {
        throw "HAR metadata is not a Release API 26 package: $sourceHar"
    }
    $moduleVersion = [string]$metadata.version
    $packageVersions[$definition.Package] = $moduleVersion
    $targetName = "harmony_agent-$($definition.Directory.Replace('_', '-'))-$moduleVersion.har"
    $targetHar = Join-Path $harDirectory $targetName
    Copy-Item -LiteralPath $sourceHar -Destination $targetHar
    $file = Get-Item -LiteralPath $targetHar
    $manifestModules += [ordered]@{
        package = $definition.Package
        version = $moduleVersion
        role = $definition.Role
        file = "hars/$targetName"
        bytes = $file.Length
        sha256 = (Get-FileHash -LiteralPath $targetHar -Algorithm SHA256).Hash
        debug = $false
        compatibleSdkVersion = 26
    }
}

$documentPaths = @(
    'docs\AGENT_SINGLE_HOST_COMPOSITION.md',
    'docs\SHUVI_WEB_SEARCH_MCP_INTEGRATION.md',
    'docs\AGENT_PROVIDER_CONNECTOR_INTEGRATION.md',
    'docs\AGENT_ASSET_CREDENTIAL_STORE.md',
    'docs\AGENT_ENCRYPTED_RDB_CONFIGURATION.md',
    'docs\LOCAL_AI_GATEWAY_INTEGRATION.md',
    'docs\BACKEND_GAP_AUDIT.md',
    'docs\TEST_MATRIX.md',
    'PROJECT_STATUS.md'
)
foreach ($relativePath in $documentPaths) {
    $source = Join-Path $workspaceRoot $relativePath
    if (Test-Path -LiteralPath $source) {
        Copy-Item -LiteralPath $source -Destination (Join-Path $docsDirectory (Split-Path -Leaf $source))
    }
}
Copy-Item -LiteralPath (Join-Path $workspaceRoot 'tools\test-shuvi-search-device.ps1') `
    -Destination (Join-Path $verificationDirectory 'test-shuvi-search-device.ps1')

$evidenceRoot = Join-Path $workspaceRoot 'artifacts\shuvi-search-device-acceptance'
$deviceEvidence = Get-ChildItem -LiteralPath $evidenceRoot -Directory -ErrorAction Stop |
    Sort-Object LastWriteTime -Descending | Where-Object {
        $summaryPath = Join-Path $_.FullName 'acceptance-summary.json'
        if (-not (Test-Path -LiteralPath $summaryPath)) { return $false }
        try { return [bool]((Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json).completed) } catch { return $false }
    } | Select-Object -First 1
if ($null -eq $deviceEvidence) { throw 'No completed Shuvi device acceptance evidence was found.' }
$deviceTarget = Join-Path $verificationDirectory ('device-' + $deviceEvidence.Name)
Copy-Item -LiteralPath $deviceEvidence.FullName -Destination $deviceTarget -Recurse
$deviceSummary = Get-Content -LiteralPath (Join-Path $deviceEvidence.FullName 'acceptance-summary.json') -Raw |
    ConvertFrom-Json

$connectorResult = Join-Path $workspaceRoot 'agent_connectors\.test\default\intermediates\test\coverage_data\test_result.txt'
if (-not (Test-Path -LiteralPath $connectorResult)) { throw 'Connector host test result is missing.' }
Copy-Item -LiteralPath $connectorResult -Destination (Join-Path $verificationDirectory 'agent-connectors-test-result.txt')
$connectorSummary = (Select-String -LiteralPath $connectorResult -Pattern '^Tests run:' | Select-Object -Last 1).Line
if ($connectorSummary -notmatch 'Tests run:\s*78, Failure:\s*0, Error:\s*0, Pass:\s*78') {
    throw 'Connector host tests did not report 78/78 passing.'
}

$unsignedHap = $null
if ($IncludeUnsignedReferenceHap) {
    New-Item -ItemType Directory -Path $referenceDirectory -Force | Out-Null
    $sourceHap = Join-Path $workspaceRoot 'test_host\build\default\outputs\default\test_host-default-unsigned.hap'
    if (-not (Test-Path -LiteralPath $sourceHap)) { throw 'Unsigned reference HAP is missing.' }
    $targetHap = Join-Path $referenceDirectory 'test_host-default-release-unsigned.hap'
    Copy-Item -LiteralPath $sourceHap -Destination $targetHap
    $unsignedHap = [ordered]@{
        file = 'reference/test_host-default-release-unsigned.hap'
        bytes = (Get-Item -LiteralPath $targetHap).Length
        sha256 = (Get-FileHash -LiteralPath $targetHap -Algorithm SHA256).Hash
        signed = $false
        purpose = 'reference host composition only'
    }
}

$searchRepository = [IO.Path]::GetFullPath((Join-Path $SearchServiceRoot '..\..'))
$searchCommit = (& git -C $searchRepository rev-parse HEAD).Trim()
$searchBranch = (& git -C $searchRepository branch --show-current).Trim()
$searchDirty = -not [string]::IsNullOrWhiteSpace(((& git -C $searchRepository status --porcelain) -join "`n"))

$overrides = [ordered]@{}
$dependencies = [ordered]@{}
foreach ($module in $manifestModules) {
    $overrides[$module.package] = 'file:./entry/libs/harmony_agent/' + $module.file
    if ($module.role -eq 'required') { $dependencies[$module.package] = $module.version }
}
$dependenciesWithStorage = [ordered]@{}
foreach ($key in $dependencies.Keys) { $dependenciesWithStorage[$key] = $dependencies[$key] }
$dependenciesWithStorage['@harmony_agent/agent-storage'] = $packageVersions['@harmony_agent/agent-storage']
$dependenciesAll = [ordered]@{}
foreach ($module in $manifestModules) { $dependenciesAll[$module.package] = $module.version }

[IO.File]::WriteAllText((Join-Path $stageDirectory 'project-overrides.example.json5'),
    ([ordered]@{ overrides = $overrides } | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $stageDirectory 'oh-package.required.example.json5'),
    ([ordered]@{ dependencies = $dependencies } | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $stageDirectory 'oh-package.with-storage.example.json5'),
    ([ordered]@{ dependencies = $dependenciesWithStorage } | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $stageDirectory 'oh-package.all-capabilities.example.json5'),
    ([ordered]@{ dependencies = $dependenciesAll } | ConvertTo-Json -Depth 5) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $stageDirectory 'INTERNET_PERMISSION_SNIPPET.json5'),
    "{`n  `"requestPermissions`": [`n    { `"name`": `"ohos.permission.INTERNET`" }`n  ]`n}`n",
    [Text.UTF8Encoding]::new($false))

$manifest = [ordered]@{
    schemaVersion = '1.0'
    packageName = 'harmony-agent-backend-sdk'
    version = $ReleaseVersion
    packageDate = (Get-Date -Format 'yyyy-MM-dd')
    sourceRepository = 'https://github.com/AlterGo-xzy/Harmony_agent.git'
    sourceCommit = $sourceCommit
    sourceBranch = $sourceBranch
    sourceDirty = $false
    compatibleSdkVersion = '26.0.0'
    targetSdkVersion = '26.0.0'
    modules = $manifestModules
    unsignedReferenceHap = $unsignedHap
    searchService = [ordered]@{
        repositoryPath = 'external: Shuvi-agent/services/search-mcp'
        branch = $searchBranch
        commit = $searchCommit
        dirty = $searchDirty
        packaged = $false
    }
    verification = [ordered]@{
        releaseHarBuilds = '7/7 successful'
        connectorHostTests = $connectorSummary
        deviceAcceptance = [ordered]@{
            completed = [bool]$deviceSummary.completed
            searchMode = [string]$deviceSummary.searchMode
            searchDevicePassed = [bool]$deviceSummary.searchDevicePassed
            transportLifecyclePassed = [bool]$deviceSummary.transportLifecyclePassed
            securityStoragePassed = [bool]$deviceSummary.securityStoragePassed
            cleanupPassed = [bool]$deviceSummary.cleanupPassed
            liveSearchExecuted = [bool]$deviceSummary.liveSearchExecuted
        }
        signedReleaseHap = $false
        productionHttpsAndAuthentication = $false
    }
    classification = 'release-candidate'
}
[IO.File]::WriteAllText((Join-Path $stageDirectory 'MANIFEST.json'),
    ($manifest | ConvertTo-Json -Depth 10) + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false))

$readme = @"
# Harmony Agent Backend SDK $ReleaseVersion

这是面向 Shuvi 应用宿主/前端服务层的 API 26 后端 Release Candidate，不是 ArkUI 页面组件包。

## 已包含

- 7 个 `debug=false` 的 Release HAR：Contracts、Core、Runtime、MCP Client、Connectors、Storage、Native Tools。
- 稳定宿主入口：任务提交、授权/澄清、取消、状态快照、事件订阅及结构化搜索来源投影。
- 搜索 MCP 注册、allowlist、授权、取消、会话重连和资源释放链路。
- AssetStore 凭据预置/读取/轮换/删除，以及加密 RDB 备份、恢复与 `rekeyEx`。
- 设备验收日志、依赖示例、SHA-256 清单和接入资料。

## 完整性结论

当前包可作为前后端集成的后端 SDK Release Candidate；尚不能标为生产 GA。剩余生产门：

1. 未配置 Tavily Key，因此设备上验证了明确的 `CONFIGURATION` 错误投影，但没有执行真实 Tavily 成功搜索。
2. 仓库没有签名材料；参考 HAP 为未签名 Release 构建，不能替代正式签名安装验收。
3. 当前搜索服务仍是本机 HDC 开发模式；正式部署需要 HTTPS、服务认证、访问控制和密钥轮换。
4. Shuvi 产品应用仍需消费这些 HAR，并在自身 Ability 生命周期中完成最终签名组合验收。
5. 根仓库尚无 LICENSE 文本，正式对外分发前需确认许可证和第三方 notice。

## 接入

将本目录复制到 Shuvi 工程的 `entry/libs/harmony_agent/`，把 `project-overrides.example.json5` 的 `overrides` 合并到工程根 `oh-package.json5`，再选择一个模块依赖示例合并到应用模块的 `oh-package.json5`。需要联网的应用模块还要合并 `INTERNET_PERMISSION_SNIPPET.json5`。

前端只调用宿主公开服务/Façade；不要直接持有 MCP Client、内部 Runtime 对象或 Tavily Key。详见 `docs/AGENT_SINGLE_HOST_COMPOSITION.md` 与 `docs/SHUVI_WEB_SEARCH_MCP_INTEGRATION.md`。

Source commit: $sourceCommit
"@
[IO.File]::WriteAllText((Join-Path $stageDirectory 'README.md'), $readme,
    [Text.UTF8Encoding]::new($false))

$filesForDigest = Get-ChildItem -LiteralPath $stageDirectory -Recurse -File |
    Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object FullName
$digestLines = foreach ($file in $filesForDigest) {
    $relative = $file.FullName.Substring($stageDirectory.Length + 1).Replace('\', '/')
    "{0}  {1}" -f (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash, $relative
}
[IO.File]::WriteAllLines((Join-Path $stageDirectory 'SHA256SUMS.txt'), $digestLines,
    [Text.UTF8Encoding]::new($false))

$reparsePoints = @(Get-ChildItem -LiteralPath $stageDirectory -Recurse -Force |
    Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
if ($reparsePoints.Count -gt 0) { throw 'Release staging tree contains a reparse point.' }
$textFiles = Get-ChildItem -LiteralPath $stageDirectory -Recurse -File |
    Where-Object { $_.Extension -in @('.md', '.txt', '.json', '.json5', '.ps1', '.log') }
$secretMatches = @($textFiles | Select-String -Pattern @(
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    '(?i)storePassword\s*[:=]\s*\S+',
    '(?i)keyPassword\s*[:=]\s*\S+',
    'sk-proj-[A-Za-z0-9_-]+',
    '(?i)^\s*TAVILY_API_KEY\s*=\s*\S+'
))
if ($secretMatches.Count -gt 0) { throw 'Potential credential material was found in release staging.' }

$zipPath = Join-Path $runDirectory ($packageName + '.zip')
Compress-Archive -LiteralPath $stageDirectory -DestinationPath $zipPath -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
[IO.File]::WriteAllText((Join-Path $runDirectory 'ZIP_SHA256.txt'),
    "$zipHash  $([IO.Path]::GetFileName($zipPath))`n", [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    PackageDirectory = $stageDirectory
    ZipPath = $zipPath
    ZipBytes = (Get-Item -LiteralPath $zipPath).Length
    ZipSha256 = $zipHash
    SourceCommit = $sourceCommit
    DeviceEvidence = $deviceEvidence.FullName
    Classification = 'release-candidate'
} | ConvertTo-Json -Depth 4
