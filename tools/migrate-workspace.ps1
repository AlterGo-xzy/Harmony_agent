# One-time, user-approved migration. Does not merge projects or delete file data.
[CmdletBinding()]
param([switch]$Execute, [switch]$CopyForLockedWorkspace)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$migrationSource = 'C:\Users\Admin\Documents\ChatGPT\Harmony Agent'
$migrationDestination = 'C:\Users\Admin\HarmonyAssistant'
$migrationBackup = 'C:\Users\Admin\HarmonyAssistant.backup-before-agent-migration'

function Assert-PlainDirectory([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Expected a normal directory, not a link: $Path"
    }
    if ($item.FullName -ne [IO.Path]::GetFullPath($Path)) {
        throw "Unexpected resolved path: $Path"
    }
}

function Get-Inventory([string]$Root, [string]$LinkRoot = $Root) {
    $files = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $links = [Collections.Generic.List[object]]::new()
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)
    [long]$bytes = 0
    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
            $relative = [IO.Path]::GetRelativePath($Root, $item.FullName)
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                if ($item.LinkType -ne 'Junction') { throw "Unsupported link: $($item.FullName)" }
                $targets = @($item.Target)
                if ($targets.Count -ne 1) { throw "Ambiguous link target: $($item.FullName)" }
                $target = [IO.Path]::GetFullPath([string]$targets[0])
                if (!$target.StartsWith($LinkRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Link points outside its project: $($item.FullName) -> $target"
                }
                $links.Add([pscustomobject]@{ Relative = $relative; TargetRelative = [IO.Path]::GetRelativePath($LinkRoot, $target) })
            } elseif ($item.PSIsContainer) {
                [void]$directories.Add($relative)
                $pending.Push($item.FullName)
            } else {
                $hash = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
                $files.Add($relative, "$($item.Length):$hash")
                $bytes += $item.Length
            }
        }
    }
    return [pscustomobject]@{ Files = $files; Directories = $directories; Links = $links; Bytes = $bytes }
}

function Test-Inventory($Before, $After, [string]$Label) {
    if ($Before.Files.Count -ne $After.Files.Count -or !$Before.Directories.SetEquals($After.Directories)) {
        throw "$Label file or directory inventory changed"
    }
    foreach ($entry in $Before.Files.GetEnumerator()) {
        if (!$After.Files.ContainsKey($entry.Key) -or $After.Files[$entry.Key] -ne $entry.Value) {
            throw "$Label file content changed: $($entry.Key)"
        }
    }
    $beforeLinks = @($Before.Links | ForEach-Object { $_.Relative + '|' + $_.TargetRelative } | Sort-Object)
    $afterLinks = @($After.Links | ForEach-Object { $_.Relative + '|' + $_.TargetRelative } | Sort-Object)
    if (@(Compare-Object $beforeLinks $afterLinks).Count -ne 0) { throw "$Label link inventory changed" }
}

function Update-ProjectLinks([string]$Root, [string]$OldRoot, $Links, [switch]$CreateMissing) {
    foreach ($link in $Links) {
        $path = [IO.Path]::GetFullPath((Join-Path $Root $link.Relative))
        $oldTarget = [IO.Path]::GetFullPath((Join-Path $OldRoot $link.TargetRelative))
        $newTarget = [IO.Path]::GetFullPath((Join-Path $Root $link.TargetRelative))
        if (!$path.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase) -or
            !$newTarget.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unsafe link path: $path"
        }
        if (!(Test-Path -LiteralPath $newTarget -PathType Container)) { throw "Missing link target: $newTarget" }
        if ($CreateMissing) {
            if (Test-Path -LiteralPath $path) { throw "Copy unexpectedly contains a link destination: $path" }
            New-Item -ItemType Junction -Path $path -Target $newTarget | Out-Null
            continue
        }
        $item = Get-Item -LiteralPath $path -Force
        if ($item.LinkType -ne 'Junction' -or [string]$item.Target -ne $oldTarget) {
            throw "Link changed since preflight: $path"
        }
        # Delete only this verified junction entry, never traverse or delete its target.
        [IO.Directory]::Delete($path, $false)
        try {
            New-Item -ItemType Junction -Path $path -Target $newTarget | Out-Null
        } catch {
            New-Item -ItemType Junction -Path $path -Target $oldTarget | Out-Null
            throw
        }
    }
}

Assert-PlainDirectory $migrationSource
Assert-PlainDirectory $migrationDestination
if (Test-Path -LiteralPath $migrationBackup) { throw "Backup already exists: $migrationBackup" }
if ([IO.Path]::GetPathRoot($migrationSource) -ne [IO.Path]::GetPathRoot($migrationDestination)) {
    throw 'This script only supports same-volume atomic directory moves'
}
$sourceBefore = Get-Inventory $migrationSource
$targetBefore = Get-Inventory $migrationDestination
Write-Output ([pscustomobject]@{
    Phase = 'Preflight'; Execute = [bool]$Execute
    Source = $migrationSource; Destination = $migrationDestination; Backup = $migrationBackup
    SourceFiles = $sourceBefore.Files.Count; SourceBytes = $sourceBefore.Bytes; SourceLinks = $sourceBefore.Links.Count
    ExistingTargetFiles = $targetBefore.Files.Count; ExistingTargetBytes = $targetBefore.Bytes; ExistingTargetLinks = $targetBefore.Links.Count
} | ConvertTo-Json)
if (!$Execute) { return }

# Directory.Move refuses an existing destination instead of nesting or merging trees.
[IO.Directory]::Move($migrationDestination, $migrationBackup)
if ($CopyForLockedWorkspace) {
    Update-ProjectLinks $migrationBackup $migrationDestination $targetBefore.Links
    New-Item -ItemType Directory -Path $migrationDestination | Out-Null
    # No /MOVE, /MIR or /PURGE: retain the locked source and never delete file data.
    # Exclude junction entries; recreate them against the new project below.
    & robocopy.exe $migrationSource $migrationDestination /E /XJ /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
    $copyExit = $LASTEXITCODE
    if ($copyExit -ge 8) { throw "Copy failed ($copyExit). Both the source and original-target backup are retained." }
    Update-ProjectLinks $migrationDestination $migrationSource $sourceBefore.Links -CreateMissing
} else {
    try {
        [IO.Directory]::Move($migrationSource, $migrationDestination)
    } catch {
        if (!(Test-Path -LiteralPath $migrationDestination)) {
            [IO.Directory]::Move($migrationBackup, $migrationDestination)
        }
        throw
    }
    try {
        New-Item -ItemType Junction -Path $migrationSource -Target $migrationDestination | Out-Null
    } catch {
        [IO.Directory]::Move($migrationDestination, $migrationSource)
        [IO.Directory]::Move($migrationBackup, $migrationDestination)
        throw
    }
    Update-ProjectLinks $migrationDestination $migrationSource $sourceBefore.Links
    Update-ProjectLinks $migrationBackup $migrationDestination $targetBefore.Links
}

Test-Inventory $sourceBefore (Get-Inventory $migrationDestination) 'Migrated project'
Test-Inventory $targetBefore (Get-Inventory $migrationBackup) 'Preserved original project'
if ($CopyForLockedWorkspace) {
    Test-Inventory $sourceBefore (Get-Inventory $migrationSource) 'Retained original source'
    $sourceStatus = 'Retained original directory; workspace switch required before link conversion'
} else {
    Test-Inventory $sourceBefore (Get-Inventory $migrationSource $migrationDestination) 'Compatibility path'
    $sourceStatus = 'Verified compatibility junction'
}
Write-Output ([pscustomobject]@{
    Phase = 'Verified'; FilesAndSHA256 = 'PASS'; OriginalBackup = 'PASS'; InternalLinks = 'PASS'; SourceStatus = $sourceStatus
    Destination = $migrationDestination; Backup = $migrationBackup
    SourceLinkType = (Get-Item -LiteralPath $migrationSource -Force).LinkType
    SourceLinkTarget = (Get-Item -LiteralPath $migrationSource -Force).Target
    MigratedFiles = $sourceBefore.Files.Count; MigratedBytes = $sourceBefore.Bytes
    PreservedFiles = $targetBefore.Files.Count; PreservedBytes = $targetBefore.Bytes
} | ConvertTo-Json -Depth 4)
