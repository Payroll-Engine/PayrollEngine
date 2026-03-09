<#
.SYNOPSIS
    Formats a SQL script file: normalises whitespace, headers, GO delimiters and
    reorders objects to resolve forward-reference dependency warnings.

.DESCRIPTION
    Reads SourceFile without modifying it and writes a reformatted copy to
    TargetFile.  The primary operation is a topological sort of all DDL objects
    (TABLE, VIEW, FUNCTION, PROCEDURE, INDEX, UNIQUE) so that every object is
    defined before any object that depends on it.

    This eliminates SQL Server warnings such as:
        "The module 'DeleteAllCaseValues' depends on the missing object
         'dbo.DeleteAllGlobalCaseValues'. The module will still be created;
         however, it cannot run successfully until the object exists."

    USE [<database>] is emitted exactly once, after the database-setup preamble
    and before the first DDL object -- not repeated for every object as SSMS
    exports it.

    Formatting normalisations applied:
      - USE [<db>] placed once after preamble, removed from individual objects
      - Consistent blank lines between logical objects
      - Trailing whitespace stripped from every line
      - GO delimiters normalised (exactly one blank line before and after)
      - CRLF output (Windows-style, compatible with SSMS / SQL Server tools)

    Full SQL pretty-printing (clause indentation etc.) is intentionally out of
    scope; pipe the output through a dedicated SQL formatter for that purpose.

.PARAMETER SourceFile
    Path to the input .sql file.  Never modified.

.PARAMETER TargetFile
    Path where the formatted output is written.  Created or overwritten.

.EXAMPLE
    .\Format-DbScript.ps1 -SourceFile ModelCreate.sql -TargetFile ModelCreate.Formatted.sql
    .\Format-DbScript.ps1 `
        -SourceFile  C:\...\Backend\Database\ModelCreate.sql `
        -TargetFile  C:\...\Backend\Database\ModelCreate.Formatted.sql
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SourceFile,
    [Parameter(Mandatory)][string]$TargetFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Section([string]$title) {
    $line = "-" * 70
    Write-Host "`n$line" -ForegroundColor DarkGray
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "$line" -ForegroundColor DarkGray
}

function Write-Ok([string]$msg)   { Write-Host "  OK:      $msg" -ForegroundColor Green  }
function Write-Info([string]$msg) { Write-Host "  INFO:    $msg" -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# Parse SQL file into GO-separated raw blocks
# ---------------------------------------------------------------------------

function Split-SqlBlocks([string]$sql) {
    $raw    = $sql -split '(?m)^\s*GO\s*$'
    $blocks = [System.Collections.Generic.List[string]]::new()
    foreach ($b in $raw) {
        $t = $b.Trim()
        if ($t.Length -gt 0) { $blocks.Add($t) }
    }
    return $blocks
}

# ---------------------------------------------------------------------------
# Group raw GO-blocks into logical DDL objects
#
# SSMS exports each object as:
#   /****** Object: ... ******/  SET ANSI_NULLS ON
#   SET QUOTED_IDENTIFIER ON
#   USE [PayrollEngine];                      <-- repeated per object in SSMS export
#   CREATE TABLE / FUNCTION / PROCEDURE ...
#
# Strategy:
#   - USE [master] and similar preamble-level USE blocks  -> kept in preamble
#   - USE [<db>] encountered inside a DDL object          -> stripped from the
#     object, db name captured; emitted ONCE after preamble by Render-SqlOutput
#   - SET option blocks                                   -> absorbed into
#     current object (companion), never trigger a flush
# ---------------------------------------------------------------------------

class SqlObject {
    [string]$ObjectType
    [string]$Schema
    [string]$Name
    [string]$FullName
    [string[]]$Blocks
    [System.Collections.Generic.HashSet[string]]$Deps
    SqlObject() { $this.Deps = [System.Collections.Generic.HashSet[string]]::new() }
}

# Module-level variable: db name detected from USE [<db>] inside DDL objects
$script:detectedDb = $null

function Group-SqlObjects([System.Collections.Generic.List[string]]$blocks) {
    $objects  = [System.Collections.Generic.List[SqlObject]]::new()
    $preamble = [System.Collections.Generic.List[string]]::new()

    $script:detectedDb = $null

    $headerRx = [regex]::new('(?i)/\*+\s*Object:\s+(\w+)\s+\[(\w+)\]\.\[(\w+)\]')
    $createRx = [regex]::new(
        '(?im)^\s*CREATE\s+(TABLE|VIEW|FUNCTION|PROCEDURE|INDEX|UNIQUE\s+INDEX|' +
        'NONCLUSTERED\s+INDEX|CLUSTERED\s+INDEX)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?')
    $useRx    = [regex]::new('(?i)^\s*USE\s+\[?(\w+)\]?\s*;?\s*$')
    $setRx    = [regex]::new(
        '(?i)^\s*SET\s+(' +
        'ANSI_NULLS|QUOTED_IDENTIFIER|ANSI_PADDING|ANSI_WARNINGS|ARITHABORT|' +
        'CONCAT_NULL_YIELDS_NULL|NUMERIC_ROUNDABORT|ANSI_NULL_DFLT_ON' +
        ')\s+(ON|OFF)\s*;?\s*$')

    $currentObj = $null

    foreach ($block in $blocks) {

        # ---- SSMS object header ----
        $hm = $headerRx.Match($block)
        if ($hm.Success) {
            if ($currentObj) { $objects.Add($currentObj) }
            $currentObj = [SqlObject]::new()
            $currentObj.ObjectType = $hm.Groups[1].Value.ToUpper()
            $currentObj.Schema     = $hm.Groups[2].Value.ToLower()
            $currentObj.Name       = $hm.Groups[3].Value.ToLower()
            $currentObj.FullName   = "$($currentObj.Schema).$($currentObj.Name)"
            $currentObj.Blocks     = @($block)
            continue
        }

        # ---- USE [db] ----
        $um = $useRx.Match($block)
        if ($um.Success) {
            if ($currentObj) {
                # Inside a DDL object: strip it, capture db name for single emission
                if (-not $script:detectedDb) {
                    $script:detectedDb = $um.Groups[1].Value
                }
                # do NOT append to object blocks
            } else {
                # Preamble-level (e.g. USE [master]): keep as-is
                $preamble.Add($block)
            }
            continue
        }

        # ---- SET option block: absorb, never flush ----
        if ($setRx.IsMatch($block)) {
            if ($currentObj) { $currentObj.Blocks += $block }
            else             { $preamble.Add($block) }
            continue
        }

        # ---- Block belongs to active object ----
        if ($currentObj) {
            $currentObj.Blocks += $block
            # Resolve type/name for objects without SSMS header
            if ($currentObj.ObjectType -eq '') {
                $cm = $createRx.Match($block)
                if ($cm.Success) {
                    $currentObj.ObjectType = $cm.Groups[1].Value.ToUpper() -replace '\s+', '_'
                    $schema = if ($cm.Groups[2].Success -and $cm.Groups[2].Value) {
                        $cm.Groups[2].Value.ToLower() } else { 'dbo' }
                    $currentObj.Schema   = $schema
                    $currentObj.Name     = $cm.Groups[3].Value.ToLower()
                    $currentObj.FullName = "$($currentObj.Schema).$($currentObj.Name)"
                }
            }
            continue
        }

        # ---- CREATE without preceding header ----
        $cm = $createRx.Match($block)
        if ($cm.Success) {
            $currentObj = [SqlObject]::new()
            $currentObj.ObjectType = $cm.Groups[1].Value.ToUpper() -replace '\s+', '_'
            $schema = if ($cm.Groups[2].Success -and $cm.Groups[2].Value) {
                $cm.Groups[2].Value.ToLower() } else { 'dbo' }
            $currentObj.Schema   = $schema
            $currentObj.Name     = $cm.Groups[3].Value.ToLower()
            $currentObj.FullName = "$($currentObj.Schema).$($currentObj.Name)"
            $currentObj.Blocks   = @($block)
            continue
        }

        # ---- Non-object block (IF, PRINT, DECLARE ...) -- flushes current object ----
        if ($currentObj) {
            $objects.Add($currentObj)
            $currentObj = $null
        }
        $preamble.Add($block)
    }

    if ($currentObj) { $objects.Add($currentObj) }
    return @{ Objects = $objects; Preamble = $preamble }
}

# ---------------------------------------------------------------------------
# Dependency detection
# ---------------------------------------------------------------------------

function Resolve-Dependencies([System.Collections.Generic.List[SqlObject]]$objects) {
    $lookup = @{}
    foreach ($obj in $objects) { $lookup[$obj.FullName] = $obj }

    $execRx = [regex]::new('(?i)EXEC(?:UTE)?\s+(?:\[?dbo\]?\.)?\[?(\w+)\]?')
    $udfRx  = [regex]::new('(?i)\[?dbo\]?\.\[?(\w+)\]?\s*\(')
    $fromRx = [regex]::new('(?i)(?:FROM|JOIN)\s+\[?(?:dbo\]?\.)?\[?(\w+)\]?(?:\s|$)')

    foreach ($obj in $objects) {
        $body = $obj.Blocks -join "`n"
        foreach ($m in $execRx.Matches($body)) {
            $ref = "dbo.$($m.Groups[1].Value.ToLower())"
            if ($lookup.ContainsKey($ref) -and $ref -ne $obj.FullName) { [void]$obj.Deps.Add($ref) }
        }
        foreach ($m in $udfRx.Matches($body)) {
            $ref = "dbo.$($m.Groups[1].Value.ToLower())"
            if ($lookup.ContainsKey($ref) -and $ref -ne $obj.FullName) { [void]$obj.Deps.Add($ref) }
        }
        foreach ($m in $fromRx.Matches($body)) {
            $ref = "dbo.$($m.Groups[1].Value.ToLower())"
            if ($lookup.ContainsKey($ref) -and $ref -ne $obj.FullName) { [void]$obj.Deps.Add($ref) }
        }
    }
}

# ---------------------------------------------------------------------------
# Topological sort (Kahn's algorithm)
# ---------------------------------------------------------------------------

function Invoke-TopologicalSort([System.Collections.Generic.List[SqlObject]]$objects) {
    $lookup   = @{}
    $inDegree = @{}
    $adjList  = @{}

    foreach ($obj in $objects) {
        $lookup[$obj.FullName]   = $obj
        $inDegree[$obj.FullName] = 0
        $adjList[$obj.FullName]  = [System.Collections.Generic.List[string]]::new()
    }
    foreach ($obj in $objects) {
        foreach ($dep in $obj.Deps) {
            if ($lookup.ContainsKey($dep)) {
                $adjList[$dep].Add($obj.FullName)
                $inDegree[$obj.FullName]++
            }
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($key in $inDegree.Keys) {
        if ($inDegree[$key] -eq 0) { $queue.Enqueue($key) }
    }

    $sorted = [System.Collections.Generic.List[SqlObject]]::new()
    while ($queue.Count -gt 0) {
        $key = $queue.Dequeue()
        $sorted.Add($lookup[$key])
        foreach ($nb in $adjList[$key]) {
            $inDegree[$nb]--
            if ($inDegree[$nb] -eq 0) { $queue.Enqueue($nb) }
        }
    }

    foreach ($obj in $objects) {
        if (-not ($sorted | Where-Object { $_.FullName -eq $obj.FullName })) {
            Write-Warn "Cycle detected involving '$($obj.FullName)' -- appended as-is"
            $sorted.Add($obj)
        }
    }
    return $sorted
}

# ---------------------------------------------------------------------------
# Render sorted objects back to SQL text
# ---------------------------------------------------------------------------

function Format-Block([string]$block) {
    $lines = $block -split "`n"
    return (($lines | ForEach-Object { $_.TrimEnd() }) -join "`r`n").Trim()
}

function Render-SqlOutput(
    [System.Collections.Generic.List[string]]$preamble,
    [System.Collections.Generic.List[SqlObject]]$sorted,
    [string]$dbName
) {
    $sb = [System.Text.StringBuilder]::new()

    # Preamble blocks (USE [master], DB creation, collation check, RCSI)
    foreach ($block in $preamble) {
        [void]$sb.Append((Format-Block $block))
        [void]$sb.Append("`r`nGO`r`n`r`n")
    }

    # Single USE [<db>] after the preamble, before all DDL objects
    if ($dbName) {
        [void]$sb.Append("USE [$dbName];")
        [void]$sb.Append("`r`nGO`r`n`r`n")
    }

    # Sorted DDL objects (without repeated USE [<db>])
    foreach ($obj in $sorted) {
        foreach ($block in $obj.Blocks) {
            [void]$sb.Append((Format-Block $block))
            [void]$sb.Append("`r`nGO`r`n`r`n")
        }
    }

    return $sb.ToString().TrimEnd() + "`r`n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Format-DbScript" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# Resolve relative paths against the caller's working directory, not System32
$callerDir = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($SourceFile)) {
    $SourceFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $SourceFile))
}
if (-not [System.IO.Path]::IsPathRooted($TargetFile)) {
    $TargetFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $TargetFile))
}

Write-Section "Input"
$sourceResolved = Resolve-Path $SourceFile -ErrorAction SilentlyContinue
if (-not $sourceResolved) {
    Write-Host "  ERROR: SourceFile not found: $SourceFile" -ForegroundColor Red
    exit 1
}
$sourcePath = $sourceResolved.Path
$fileInfo   = Get-Item $sourcePath
Write-Info "Source : $sourcePath ($([Math]::Round($fileInfo.Length / 1KB, 1)) KB)"
Write-Info "Target : $TargetFile"

Write-Section "Parsing"
$sql    = [System.IO.File]::ReadAllText($sourcePath)
$blocks = Split-SqlBlocks $sql
Write-Info "Raw GO-blocks : $($blocks.Count)"

$grouped  = Group-SqlObjects $blocks
$preamble = $grouped.Preamble
$objects  = $grouped.Objects
Write-Info "Preamble blocks : $($preamble.Count)"
Write-Info "DDL objects     : $($objects.Count)"
if ($script:detectedDb) {
    Write-Info "Database        : $($script:detectedDb)  (USE emitted once after preamble)"
}

$typeGroups = $objects | Group-Object ObjectType | Sort-Object Name
foreach ($g in $typeGroups) {
    Write-Info "  $($g.Name.PadRight(25)) $($g.Count)"
}

Write-Section "Dependency Resolution"
Resolve-Dependencies $objects

$withDeps = @($objects | Where-Object { $_.Deps.Count -gt 0 })
Write-Info "Objects with dependencies : $($withDeps.Count)"
foreach ($obj in $withDeps) {
    Write-Info "  $($obj.FullName) -> $($obj.Deps -join ', ')"
}

Write-Section "Topological Sort"
$sorted = Invoke-TopologicalSort $objects
Write-Ok "Sort complete -- $($sorted.Count) objects ordered"

Write-Section "Writing Output"
$targetDir = Split-Path $TargetFile -Parent
if ($targetDir -and -not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

$output = Render-SqlOutput $preamble $sorted $script:detectedDb
[System.IO.File]::WriteAllText($TargetFile, $output, [System.Text.Encoding]::UTF8)

$outInfo = Get-Item $TargetFile
Write-Ok "Written: $TargetFile ($([Math]::Round($outInfo.Length / 1KB, 1)) KB)"

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray
Write-Host "  DONE  |  $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
exit 0
