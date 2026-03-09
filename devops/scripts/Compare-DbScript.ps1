<#
.SYNOPSIS
    Compares two formatted SQL script files and generates a delta (update) script.

.DESCRIPTION
    Parses BaselineFile and CurrentFile into named DDL objects using the same
    block-grouping logic as Format-DbScript and computes the difference:

      Added    -- objects in Current but not in Baseline  → CREATE statements
      Removed  -- objects in Baseline but not in Current  → DROP statements
      Modified -- objects in both but with different body  → DROP + CREATE

    Both files should be pre-processed by Format-DbScript.ps1 so that object
    ordering and whitespace are normalised before comparison.  Without prior
    formatting the diff may produce false positives caused by comment or
    whitespace differences.

    The generated delta script can be applied directly to a database that
    matches the Baseline schema to bring it to the Current schema.

.PARAMETER BaselineFile
    Formatted SQL file representing the old / source state.

.PARAMETER CurrentFile
    Formatted SQL file representing the new / target state.

.PARAMETER TargetFile
    Path where the delta .sql script is written.  Created or overwritten.

.EXAMPLE
    .\Compare-DbScript.ps1 `
        -BaselineFile ModelCreate.Formatted.sql `
        -CurrentFile  ModelCreate.New.Formatted.sql `
        -TargetFile   ModelUpdate.sql

    .\Compare-DbScript.ps1 `
        -BaselineFile Snapshot_Create.sql `
        -CurrentFile  ModelCreate.sql `
        -TargetFile   ModelUpdate_$(Get-Date -Format 'yyyyMMdd').sql
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaselineFile,
    [Parameter(Mandatory)][string]$CurrentFile,
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

function Write-Ok([string]$msg)   { Write-Host "  OK:      $msg" -ForegroundColor Green   }
function Write-Info([string]$msg) { Write-Host "  INFO:    $msg" -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow  }
function Write-Add([string]$msg)  { Write-Host "  ADD:     $msg" -ForegroundColor Cyan    }
function Write-Drop([string]$msg) { Write-Host "  DROP:    $msg" -ForegroundColor Red     }
function Write-Mod([string]$msg)  { Write-Host "  MOD:     $msg" -ForegroundColor Yellow  }

# ---------------------------------------------------------------------------
# SQL Parser  (same algorithm as DbScriptFormat)
# ---------------------------------------------------------------------------

class DiffObject {
    [string]$ObjectType
    [string]$FullName
    [string]$NormalisedBody   # whitespace-normalised, used for equality
    [string]$RawBody          # original text, used for output
}

function Split-SqlBlocks([string]$sql) {
    $raw    = $sql -split '(?m)^\s*GO\s*$'
    $blocks = [System.Collections.Generic.List[string]]::new()
    foreach ($b in $raw) {
        $t = $b.Trim()
        if ($t.Length -gt 0) { $blocks.Add($t) }
    }
    return $blocks
}

function Normalize-Body([string]$body) {
    # Strip SSMS header comments (contain date stamps), normalise whitespace
    $noHeader  = $body -replace '/\*+.*?\*+/', '' -replace '--[^\r\n]*', ''
    $noSpace   = $noHeader -replace '\s+', ' '
    return $noSpace.Trim().ToLower()
}

function Parse-SqlFile([string]$path) {
    $sql    = [System.IO.File]::ReadAllText($path)
    $blocks = Split-SqlBlocks $sql

    $headerPattern = [regex]'(?i)/\*+\s*Object:\s+(\w+)\s+\[(\w+)\]\.\[(\w+)\]'
    $createPattern = [regex]'(?im)^\s*CREATE\s+(TABLE|VIEW|FUNCTION|PROCEDURE|UNIQUE\s+INDEX|NONCLUSTERED\s+INDEX|CLUSTERED\s+INDEX|INDEX)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?'

    $objects = [System.Collections.Generic.Dictionary[string, DiffObject]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)

    $currentKey    = $null
    $currentType   = $null
    $currentBlocks = [System.Collections.Generic.List[string]]::new()

    $flushCurrent = {
        if ($currentKey -and $currentBlocks.Count -gt 0) {
            $raw   = $currentBlocks -join "`r`nGO`r`n"
            $dobj  = [DiffObject]::new()
            $dobj.ObjectType      = $currentType
            $dobj.FullName        = $currentKey
            $dobj.RawBody         = $raw
            $dobj.NormalisedBody  = Normalize-Body $raw
            $objects[$currentKey] = $dobj
        }
        $currentKey    = $null
        $currentType   = $null
        $currentBlocks.Clear()
    }

    foreach ($block in $blocks) {
        $hm = $headerPattern.Match($block)
        if ($hm.Success) {
            & $flushCurrent
            $currentKey  = "$($hm.Groups[2].Value.ToLower()).$($hm.Groups[3].Value.ToLower())"
            $currentType = $hm.Groups[1].Value.ToUpper()
            $currentBlocks.Add($block)
            continue
        }

        $cm = $createPattern.Match($block)
        if ($cm.Success) {
            if (-not $currentKey) {
                # CREATE without preceding header
                $schema      = if ($cm.Groups[2].Success -and $cm.Groups[2].Value) { $cm.Groups[2].Value.ToLower() } else { 'dbo' }
                $currentKey  = "$schema.$($cm.Groups[3].Value.ToLower())"
                $currentType = $cm.Groups[1].Value.ToUpper() -replace '\s+', '_'
            }
            $currentBlocks.Add($block)
            continue
        }

        if ($currentKey) {
            # SET ANSI_NULLS, SET QUOTED_IDENTIFIER etc. belong to the current object
            if ($block -match '(?i)^\s*SET\s+(ANSI_NULLS|QUOTED_IDENTIFIER)\s+(ON|OFF)\s*$') {
                $currentBlocks.Add($block)
                continue
            }
            & $flushCurrent
        }

        # Non-object block -- skip (preamble handled separately)
    }
    & $flushCurrent

    return $objects
}

# ---------------------------------------------------------------------------
# DROP statement builder
# ---------------------------------------------------------------------------

function Build-DropStatement([DiffObject]$obj) {
    $typeKw = switch -Wildcard ($obj.ObjectType) {
        'PROCEDURE'           { 'PROCEDURE' }
        'STOREDPROCEDURE'     { 'PROCEDURE' }   # SSMS header style
        'FUNCTION'            { 'FUNCTION'  }
        '*FUNCTION*'          { 'FUNCTION'  }
        'VIEW'                { 'VIEW'      }
        'TABLE'               { 'TABLE'     }
        '*INDEX*'             { $null       }   # handled via ALTER TABLE
        default               { $null       }
    }

    $parts  = $obj.FullName -split '\.'
    $schema = $parts[0]
    $name   = $parts[1]

    if ($typeKw -eq 'TABLE') {
        return @"
IF OBJECT_ID('[$schema].[$name]', 'U') IS NOT NULL
    DROP TABLE [$schema].[$name];
GO
"@
    }

    if ($typeKw) {
        return @"
IF OBJECT_ID('[$schema].[$name]') IS NOT NULL
    DROP $typeKw [$schema].[$name];
GO
"@
    }

    # Index: cannot generate without table name in this context
    return "-- NOTE: manual DROP required for $($obj.ObjectType) [$schema].[$name]`r`nGO`r`n"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Compare-DbScript" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# Resolve relative paths against the caller's working directory, not System32
$callerDir = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($BaselineFile)) {
    $BaselineFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $BaselineFile))
}
if (-not [System.IO.Path]::IsPathRooted($CurrentFile)) {
    $CurrentFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $CurrentFile))
}
if (-not [System.IO.Path]::IsPathRooted($TargetFile)) {
    $TargetFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $TargetFile))
}

Write-Section "Input Files"

foreach ($f in @($BaselineFile, $CurrentFile)) {
    if (-not (Test-Path $f)) {
        Write-Host "  ERROR: File not found: $f" -ForegroundColor Red
        exit 1
    }
}

$bInfo = Get-Item $BaselineFile
$cInfo = Get-Item $CurrentFile
Write-Info "Baseline : $BaselineFile ($([Math]::Round($bInfo.Length / 1KB, 1)) KB)"
Write-Info "Current  : $CurrentFile ($([Math]::Round($cInfo.Length / 1KB, 1)) KB)"

Write-Section "Parsing"
$baseline = Parse-SqlFile $BaselineFile
$current  = Parse-SqlFile $CurrentFile
Write-Info "Baseline objects : $($baseline.Count)"
Write-Info "Current  objects : $($current.Count)"

# ---------------------------------------------------------------------------
# Diff
# ---------------------------------------------------------------------------

Write-Section "Diff"

$added    = [System.Collections.Generic.List[DiffObject]]::new()
$removed  = [System.Collections.Generic.List[DiffObject]]::new()
$modified = [System.Collections.Generic.List[DiffObject]]::new()
$unchanged = 0

foreach ($key in $current.Keys) {
    if (-not $baseline.ContainsKey($key)) {
        $added.Add($current[$key])
        Write-Add $key
    } elseif ($current[$key].NormalisedBody -ne $baseline[$key].NormalisedBody) {
        $modified.Add($current[$key])
        Write-Mod $key
    } else {
        $unchanged++
    }
}

foreach ($key in $baseline.Keys) {
    if (-not $current.ContainsKey($key)) {
        $removed.Add($baseline[$key])
        Write-Drop $key
    }
}

Write-Info "Added   : $($added.Count)"
Write-Info "Removed : $($removed.Count)"
Write-Info "Modified: $($modified.Count)"
Write-Info "Equal   : $unchanged"

if ($added.Count -eq 0 -and $removed.Count -eq 0 -and $modified.Count -eq 0) {
    Write-Ok "No differences found -- no delta script generated"
    exit 0
}

# ---------------------------------------------------------------------------
# Generate delta script
# ---------------------------------------------------------------------------

Write-Section "Generating Delta Script"

$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("-- ============================================================")
[void]$sb.AppendLine("-- Delta Update Script")
[void]$sb.AppendLine("-- Baseline : $(Split-Path $BaselineFile -Leaf)")
[void]$sb.AppendLine("-- Current  : $(Split-Path $CurrentFile  -Leaf)")
[void]$sb.AppendLine("-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("-- Changes  : +$($added.Count) added / -$($removed.Count) removed / ~$($modified.Count) modified")
[void]$sb.AppendLine("-- ============================================================")
[void]$sb.AppendLine("GO")
[void]$sb.AppendLine("")

# -- 1. Drop removed objects -------------------------------------------------
if ($removed.Count -gt 0) {
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Removed objects ($($removed.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")

    # Drop in safe order: SPs and functions before tables
    $dropOrder = $removed | Sort-Object {
        switch ($_.ObjectType) {
            'PROCEDURE' { 1 }
            { $_ -like '*FUNCTION*' } { 2 }
            'VIEW'      { 3 }
            'TABLE'     { 5 }
            default     { 4 }
        }
    }

    foreach ($obj in $dropOrder) {
        [void]$sb.AppendLine((Build-DropStatement $obj))
        [void]$sb.AppendLine("")
    }
}

# -- 2. Drop modified objects (will be re-created below) --------------------
if ($modified.Count -gt 0) {
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Modified objects -- drop before re-create ($($modified.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")

    foreach ($obj in $modified) {
        # Only drop/recreate programmable objects; for tables emit ALTER TABLE stubs
        if ($obj.ObjectType -eq 'TABLE') {
            [void]$sb.AppendLine("-- TODO: Table [$($obj.FullName)] was modified.")
            [void]$sb.AppendLine("-- Review column differences and write ALTER TABLE statements manually.")
            [void]$sb.AppendLine("GO")
            [void]$sb.AppendLine("")
        } else {
            [void]$sb.AppendLine((Build-DropStatement $obj))
            [void]$sb.AppendLine("")
        }
    }
}

# -- 3. Create added objects -------------------------------------------------
if ($added.Count -gt 0) {
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Added objects ($($added.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")

    foreach ($obj in $added) {
        [void]$sb.AppendLine($obj.RawBody)
        [void]$sb.AppendLine("GO")
        [void]$sb.AppendLine("")
    }
}

# -- 4. Re-create modified programmable objects -----------------------------
$modProg = @($modified | Where-Object { $_.ObjectType -ne 'TABLE' })
if ($modProg.Count -gt 0) {
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Modified objects -- re-create ($($modProg.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")

    foreach ($obj in $modProg) {
        [void]$sb.AppendLine($obj.RawBody)
        [void]$sb.AppendLine("GO")
        [void]$sb.AppendLine("")
    }
}

# Write output
$targetDir = Split-Path $TargetFile -Parent
if ($targetDir -and -not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

[System.IO.File]::WriteAllText($TargetFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
$outInfo = Get-Item $TargetFile
Write-Ok "Written: $TargetFile ($([Math]::Round($outInfo.Length / 1KB, 1)) KB)"

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray
Write-Host "  RESULT: +$($added.Count) added  -$($removed.Count) removed  ~$($modified.Count) modified  =$unchanged unchanged" -ForegroundColor Cyan
Write-Host "  Elapsed: $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor DarkGray
exit 0
