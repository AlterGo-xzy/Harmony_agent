# One-time migration approved by the user: copy, verify, then delete the old workspace.
[CmdletBinding()]
param([switch]$Execute)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$migrationSource = 'C:\Users\Admin\Documents\ChatGPT\Harmony Agent'
$migrationShortSource = 'C:\Users\Admin\Documents\ChatGPT\HARMON~1'
$migrationTarget = 'D:\Harmony_agent'
$migrationTombstone = 'C:\Users\Admin\Documents\ChatGPT\Harmony Agent.migration-delete-pending'

function Get-ProjectInventory([string]$Root) {
    $files = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $directories = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $links = [Collections.Generic.List[object]]::new()
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)
    [long]$bytes = 0
    while ($pending.Count -gt 0) {
        foreach ($item in Get-ChildItem -LiteralPath $pending.Pop() -Force) {
            $relative = [IO.Path]::GetRelativePath($Root, $item.FullName)
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                if ($item.LinkType -ne 'Junction') { throw "Unsupported reparse point: $($item.FullName)" }
                $target = [IO.Path]::GetFullPath([string]$item.Target)
                if (!$target.StartsWith($Root + '\', [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Link points outside the approved project: $($item.FullName) -> $target"
                }
                $links.Add([pscustomobject]@{ Relative = $relative; TargetRelative = [IO.Path]::GetRelativePath($Root, $target) })
            } elseif ($item.PSIsContainer) {
                [void]$directories.Add($relative)
                $pending.Push($item.FullName)
            } else {
                $files.Add($relative, "$($item.Length):$((Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash)")
                $bytes += $item.Length
            }
        }
    }
    return [pscustomobject]@{ Files = $files; Directories = $directories; Links = $links; Bytes = $bytes }
}

function Assert-SameInventory($Before, $After) {
    if ($Before.Files.Count -ne $After.Files.Count -or !$Before.Directories.SetEquals($After.Directories)) {
        throw 'File or directory inventory differs; the original workspace must not be deleted'
    }
    foreach ($entry in $Before.Files.GetEnumerator()) {
        if (!$After.Files.ContainsKey($entry.Key) -or $After.Files[$entry.Key] -ne $entry.Value) {
            throw "File size/SHA256 mismatch: $($entry.Key). The original workspace must not be deleted."
        }
    }
    $beforeLinks = @($Before.Links | ForEach-Object { $_.Relative + '|' + $_.TargetRelative } | Sort-Object)
    $afterLinks = @($After.Links | ForEach-Object { $_.Relative + '|' + $_.TargetRelative } | Sort-Object)
    if (@(Compare-Object $beforeLinks $afterLinks).Count -ne 0) { throw 'Dependency link inventory differs' }
}

function Assert-MigrationRoots {
    $source = Get-Item -LiteralPath $migrationSource -Force
    $short = Get-Item -LiteralPath $migrationShortSource -Force
    $target = Get-Item -LiteralPath $migrationTarget -Force
    foreach ($item in @($source, $target)) {
        if (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Migration root is not a plain directory: $($item.FullName)"
        }
    }
    if ($source.FullName -ne $migrationSource -or $short.FullName -ne $migrationSource -or $target.FullName -ne $migrationTarget) {
        throw 'The resolved source or target is not the exact user-approved directory'
    }
    if (@(Get-ChildItem -LiteralPath $migrationTarget -Force).Count -ne 0) { throw 'Target is not empty; refusing to overwrite it' }
    if (Test-Path -LiteralPath $migrationTombstone) { throw 'Temporary deletion directory already exists' }
    $drive = [IO.DriveInfo]::new('D:\')
    if (!$drive.IsReady -or $drive.DriveType -ne [IO.DriveType]::Fixed -or $drive.DriveFormat -ne 'NTFS') {
        throw 'Target must be a ready local NTFS volume'
    }
}

Assert-MigrationRoots
$before = Get-ProjectInventory $migrationSource
Write-Output ([pscustomobject]@{
    Phase = 'Preflight'; Execute = [bool]$Execute; Source = $migrationSource; Target = $migrationTarget
    Files = $before.Files.Count; Bytes = $before.Bytes; Junctions = $before.Links.Count
    DeleteSourceAfterVerification = $true; KeepCompatibilityJunction = $false
    ExcludedFromChanges = @('C:\Users\Admin\HarmonyAssistant', 'C:\Users\Admin\HarmonyAssistant.backup-before-agent-migration')
} | ConvertTo-Json -Depth 4)
if (!$Execute) { return }

# /XJ avoids following dependency junctions. No /MIR, /MOVE or /PURGE.
& robocopy.exe $migrationSource $migrationTarget /E /XJ /COPY:DAT /DCOPY:DAT /R:1 /W:1 /NFL /NDL /NP /NJH /NJS
$copyExit = $LASTEXITCODE
if ($copyExit -ge 8) { throw "Robocopy failed: $copyExit. Original workspace is retained." }
foreach ($link in $before.Links) {
    $linkPath = [IO.Path]::GetFullPath((Join-Path $migrationTarget $link.Relative))
    $linkTarget = [IO.Path]::GetFullPath((Join-Path $migrationTarget $link.TargetRelative))
    if (!$linkPath.StartsWith($migrationTarget + '\', [StringComparison]::OrdinalIgnoreCase) -or
        !$linkTarget.StartsWith($migrationTarget + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Unsafe dependency link path'
    }
    if (Test-Path -LiteralPath $linkPath) { throw "Link path unexpectedly exists: $linkPath" }
    if (!(Test-Path -LiteralPath $linkTarget -PathType Container)) { throw "Dependency target missing: $linkTarget" }
    New-Item -ItemType Junction -Path $linkPath -Target $linkTarget | Out-Null
}
Assert-SameInventory $before (Get-ProjectInventory $migrationTarget)
Assert-SameInventory $before (Get-ProjectInventory $migrationSource)
Write-Output 'COPY VERIFIED: all relative file paths, directory paths, lengths, SHA256 values and dependency links match.'

# First atomically rename the source to a narrowly named deletion target. If the
# current Codex workspace is still locked, leave it completely intact rather
# than deleting its contents and discovering the lock only at the final step.
$sourceDeleted = $false
$deleteFailure = $null
try {
    $sourceItem = Get-Item -LiteralPath $migrationSource -Force
    if ($sourceItem.FullName -ne $migrationSource -or ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Source changed after verification; refusing cleanup'
    }
    [IO.Directory]::Move($migrationSource, $migrationTombstone)
} catch {
    $deleteFailure = $_.Exception.Message
}
if (!$deleteFailure) {
    # Remove only the known junction entries; do not recurse through their targets.
    foreach ($link in $before.Links) {
        $path = [IO.Path]::GetFullPath((Join-Path $migrationTombstone $link.Relative))
        if (!$path.StartsWith($migrationTombstone + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup path' }
        $item = Get-Item -LiteralPath $path -Force
        $expectedTarget = Join-Path $migrationSource $link.TargetRelative
        if ($item.LinkType -ne 'Junction' -or [string]$item.Target -ne $expectedTarget) { throw 'Cleanup link changed' }
        [IO.Directory]::Delete($path, $false)
    }
    $deleteRoot = Get-Item -LiteralPath $migrationTombstone -Force
    if ($deleteRoot.FullName -ne $migrationTombstone -or ($deleteRoot.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
        @(Get-ChildItem -LiteralPath $migrationTombstone -Force -Recurse -Attributes ReparsePoint).Count -ne 0) {
        throw 'Deletion root or remaining reparse points failed validation'
    }
    Remove-Item -LiteralPath $migrationTombstone -Recurse -Force
    $sourceDeleted = !(Test-Path -LiteralPath $migrationSource) -and !(Test-Path -LiteralPath $migrationShortSource) -and !(Test-Path -LiteralPath $migrationTombstone)
}
Write-Output ([pscustomobject]@{
    Phase = 'Result'; Destination = $migrationTarget; CopyAndSHA256 = 'PASS'; DependencyLinks = 'PASS'
    CopiedFiles = $before.Files.Count; CopiedBytes = $before.Bytes; RebuiltJunctions = $before.Links.Count
    SourceDeleted = $sourceDeleted; SourceDeletionError = $deleteFailure
    OtherLocationsWereNotModified = $true
} | ConvertTo-Json -Depth 4)
