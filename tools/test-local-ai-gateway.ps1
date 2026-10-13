[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $OutputPath,

    [string] $ExpectedText = 'HARMONY_AGENT_GATEWAY_OK'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$workspaceRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$outputFullPath = [IO.Path]::GetFullPath($OutputPath)
if (-not $outputFullPath.StartsWith($workspaceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputPath must stay inside the Harmony Agent workspace.'
}

$baseUrl = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_BASE_URL', 'Process')
$token = [Environment]::GetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', 'Process')
if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($token)) {
    throw 'Gateway base URL and managed client token must be injected by aigw run.'
}

$uri = [Uri]$baseUrl
if ($uri.Scheme -ne 'http' -or ($uri.Host -ne '127.0.0.1' -and $uri.Host -ne 'localhost') -or
    -not [string]::IsNullOrEmpty($uri.Query) -or -not [string]::IsNullOrEmpty($uri.Fragment)) {
    throw 'The injected gateway URL must be an HTTP loopback URL.'
}

$rootUrl = $baseUrl.TrimEnd('/')
$apiBaseUrl = if ($rootUrl.EndsWith('/v1', [StringComparison]::OrdinalIgnoreCase)) {
    $rootUrl
} else {
    $rootUrl + '/v1'
}
$gatewayRootUrl = if ($rootUrl.EndsWith('/v1', [StringComparison]::OrdinalIgnoreCase)) {
    $rootUrl.Substring(0, $rootUrl.Length - 3)
} else {
    $rootUrl
}

$startedAt = [DateTimeOffset]::Now
$summary = [ordered]@{
    schemaVersion = '1.0'
    startedAt = $startedAt.ToString('o')
    finishedAt = $null
    baseUrl = $apiBaseUrl
    modelAlias = 'aigw/default'
    readyStatus = $null
    chatStatus = $null
    contentMatched = $false
    finishReason = $null
    usage = $null
    credentialInjected = $true
    credentialRecorded = $false
    rawResponseRecorded = $false
    providerErrorCode = $null
    providerErrorType = $null
    errorCategory = $null
}

$client = [Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromSeconds(60)
$client.DefaultRequestHeaders.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token)
$exitCode = 1

try {
    $readyResponse = $client.GetAsync($gatewayRootUrl + '/ready').GetAwaiter().GetResult()
    try {
        $summary.readyStatus = [int]$readyResponse.StatusCode
    } finally {
        $readyResponse.Dispose()
    }
    if ($summary.readyStatus -lt 200 -or $summary.readyStatus -ge 300) {
        $summary.errorCategory = 'GatewayNotReady'
    } else {
        $payload = [ordered]@{
            model = 'aigw/default'
            messages = @(
                [ordered]@{
                    role = 'user'
                    content = "Return exactly $ExpectedText"
                }
            )
            max_tokens = 24
            temperature = 0
            stream = $false
        }
        $requestBody = $payload | ConvertTo-Json -Depth 8 -Compress
        $requestContent = [Net.Http.StringContent]::new($requestBody, [Text.Encoding]::UTF8, 'application/json')
        try {
            $chatResponse = $client.PostAsync($apiBaseUrl + '/chat/completions', $requestContent).GetAwaiter().GetResult()
            try {
                $summary.chatStatus = [int]$chatResponse.StatusCode
                if ($chatResponse.IsSuccessStatusCode) {
                    $raw = $chatResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    $decoded = $raw | ConvertFrom-Json
                    if ($null -eq $decoded.choices -or $decoded.choices.Count -ne 1 -or
                        $null -eq $decoded.choices[0].message -or
                        $decoded.choices[0].message.content -isnot [string]) {
                        $summary.errorCategory = 'ResponseShape'
                    } else {
                        $summary.contentMatched = $decoded.choices[0].message.content.Trim() -eq $ExpectedText
                        $summary.finishReason = [string]$decoded.choices[0].finish_reason
                        if ($null -ne $decoded.usage) {
                            $summary.usage = [ordered]@{
                                promptTokens = [int64]$decoded.usage.prompt_tokens
                                completionTokens = [int64]$decoded.usage.completion_tokens
                                totalTokens = [int64]$decoded.usage.total_tokens
                            }
                        }
                        if ($summary.contentMatched) {
                            $exitCode = 0
                        } else {
                            $summary.errorCategory = 'UnexpectedContent'
                        }
                    }
                } else {
                    $rawError = $chatResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
                    try {
                        $decodedError = $rawError | ConvertFrom-Json
                        if ($null -ne $decodedError.error) {
                            if ($decodedError.error.code -is [string]) {
                                $summary.providerErrorCode = $decodedError.error.code
                            }
                            if ($decodedError.error.type -is [string]) {
                                $summary.providerErrorType = $decodedError.error.type
                            }
                        }
                    } catch {
                        # Error bodies remain unrecorded when they are not a recognized JSON envelope.
                    }
                    $summary.errorCategory = 'ChatHttpStatus'
                }
            } finally {
                $chatResponse.Dispose()
            }
        } finally {
            $requestContent.Dispose()
        }
    }
} catch {
    $summary.errorCategory = $_.Exception.GetType().FullName
} finally {
    $client.Dispose()
    [Environment]::SetEnvironmentVariable('HARMONY_AGENT_GATEWAY_TOKEN', $null, 'Process')
    $token = $null
    $summary.finishedAt = [DateTimeOffset]::Now.ToString('o')
    $parent = Split-Path -Parent $outputFullPath
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    [IO.File]::WriteAllText(
        $outputFullPath,
        ($summary | ConvertTo-Json -Depth 8),
        [Text.UTF8Encoding]::new($false)
    )
    $summary | ConvertTo-Json -Depth 8
}

exit $exitCode
