[CmdletBinding()]
param(
    [string]$OutputDirectory = '',
    [switch]$BuildRelease
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$workspace = Split-Path -Parent $PSScriptRoot
$artifactsRoot = Join-Path $workspace 'artifacts'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $OutputDirectory = Join-Path $artifactsRoot "local-agent-testkit-$stamp"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $workspace $OutputDirectory
}
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
$allowedPrefix = [System.IO.Path]::GetFullPath($artifactsRoot) + [System.IO.Path]::DirectorySeparatorChar
if (-not $outputRoot.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputDirectory must be a new directory below $artifactsRoot."
}
if (Test-Path -LiteralPath $outputRoot) {
    throw "OutputDirectory already exists: $outputRoot"
}

function Copy-ModuleSource {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$DestinationRoot
    )
    $source = Join-Path $workspace $Name
    $destination = Join-Path $DestinationRoot $Name
    New-Item -ItemType Directory -Path $destination | Out-Null
    Get-ChildItem -LiteralPath $source -File | Copy-Item -Destination $destination
    Copy-Item -LiteralPath (Join-Path $source 'src') -Destination $destination -Recurse
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $workspace 'AppScope') -Destination $outputRoot -Recurse
Copy-Item -LiteralPath (Join-Path $workspace 'hvigor') -Destination $outputRoot -Recurse
Copy-Item -LiteralPath (Join-Path $workspace 'hvigorfile.ts') -Destination $outputRoot
Copy-Item -LiteralPath (Join-Path $workspace 'oh-package.json5') -Destination $outputRoot
Copy-Item -LiteralPath (Join-Path $workspace 'oh_modules') -Destination $outputRoot -Recurse

Copy-ModuleSource -Name 'agent_contracts' -DestinationRoot $outputRoot
Copy-ModuleSource -Name 'agent_testkit' -DestinationRoot $outputRoot
$testkitScope = Join-Path $outputRoot 'agent_testkit\oh_modules\@harmony_agent'
New-Item -ItemType Directory -Path $testkitScope -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $outputRoot 'agent_contracts') `
    -Destination (Join-Path $testkitScope 'agent-contracts') -Recurse

$isolatedBuildProfile = @'
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "targetSdkVersion": "26.0.0",
        "compatibleSdkVersion": "26.0.0",
        "runtimeOS": "HarmonyOS",
        "buildOption": {
          "strictMode": {
            "caseSensitiveCheck": true,
            "useNormalizedOHMUrl": true
          }
        }
      }
    ],
    "buildModeSet": [{ "name": "debug" }, { "name": "release" }]
  },
  "modules": [
    {
      "name": "agent_contracts",
      "srcPath": "./agent_contracts",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    },
    {
      "name": "agent_testkit",
      "srcPath": "./agent_testkit",
      "targets": [{ "name": "default", "applyToProducts": ["default"] }]
    }
  ]
}
'@
Set-Content -LiteralPath (Join-Path $outputRoot 'build-profile.json5') `
    -Value $isolatedBuildProfile -Encoding utf8NoBOM

$hvigor = 'D:\DevEco\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
$env:DEVECO_SDK_HOME = 'D:\DevEco\DevEco Studio\sdk'
Push-Location $outputRoot
try {
    & $hvigor --mode module -p module=agent_testkit@default -p product=default test --no-daemon
    if ($LASTEXITCODE -ne 0) { throw "TestKit tests failed with exit code $LASTEXITCODE" }
    if ($BuildRelease) {
        & $hvigor --mode module -p module=agent_testkit@default -p product=default `
            -p buildMode=release assembleHar --no-daemon
        if ($LASTEXITCODE -ne 0) { throw "TestKit Release HAR build failed with exit code $LASTEXITCODE" }
    }
} finally {
    Pop-Location
}

$resultPath = Join-Path $outputRoot `
    'agent_testkit\.test\default\intermediates\test\coverage_data\test_result.txt'
Write-Output "TEST_RESULT=$resultPath"
if ($BuildRelease) {
    $harPath = Join-Path $outputRoot 'agent_testkit\build\default\outputs\default\agent_testkit.har'
    Write-Output "RELEASE_HAR=$harPath"
}
