#
# .SYNOPSIS
#     Compares two formatted SQL script files and generates a delta (update) script.
#
# .DESCRIPTION
#     Parses BaselineFile and CurrentFile into named DDL objects using the same
#     block-grouping logic as Format-DbScript and computes the difference:
#
#       Added    -- objects in Current but not in Baseline  -> CREATE statements
#       Removed  -- objects in Baseline but not in Current  -> DROP statements
#       Modified -- objects in both but with different body  -> DROP + CREATE
#
#     Both files should be pre-processed by Format-DbScript.ps1 so that object
#     ordering and whitespace are normalised before comparison.  Without prior
#     formatting the diff may produce false positives caused by comment or
#     whitespace differences.
#
#     The generated delta script can be applied directly to a database that
#     matches the Baseline schema to bring it to the Current schema.
#
# .PARAMETER BaselineFile
#     Formatted SQL file representing the old / source state.
#
# .PARAMETER CurrentFile
#     Formatted SQL file representing the new / target state.
#
# .PARAMETER TargetFile
#     Path where the delta .sql script is written.  Created or overwritten.
#
# .EXAMPLE
#     .\Compare-DbScript.ps1 `
#         -BaselineFile ModelCreate.Formatted.sql `
#         -CurrentFile  ModelCreate.New.Formatted.sql `
#         -TargetFile   ModelUpdate.sql

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
    [string]$FullName          # lowercase key, used for dictionary lookups and comparison
    [string]$OriginalFullName  # original casing, used for SQL output
    [string]$NormalisedBody    # whitespace-normalised, used for equality
    [string]$RawBody           # original text, used for output
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
    # Strip SSMS header comments (contain date stamps) and single-line comments
    $s = $body -replace '/\*+.*?\*+/', '' -replace '--[^\r\n]*', ''
    # Strip SET ANSI_NULLS / SET QUOTED_IDENTIFIER -- boilerplate that may or may not
    # appear depending on whether the source is an SSMS export or a rebuild-style file.
    $s = $s -replace '(?i)\bSET\s+(ANSI_NULLS|QUOTED_IDENTIFIER)\s+(ON|OFF)\b', ''
    # Strip standalone GO batch separators.
    # SSMS-style objects have multiple blocks (header + SET opts + CREATE) joined with
    # \r\nGO\r\n, while rebuild-style objects have only a single CREATE block.
    # Stripping the GO separators ensures both produce the same normalised body.
    $s = $s -replace '\r\nGO\r\n', ' ' -replace '\nGO\n', ' '
    # Collapse all whitespace sequences to a single space
    $s = $s -replace '\s+', ' '
    # Normalise spaces inside parentheses:
    # SSMS-exported files often format multi-line IF conditions as  IF ( \n  expr \n  )
    # while rebuilt files use                                        IF (expr)
    # After whitespace collapse this produces  "( expr )" vs "(expr)" -- strip the spaces.
    $s = $s -replace '\(\s+', '(' -replace '\s+\)', ')'
    return $s.Trim().ToLower()
}

function Parse-SqlFile([string]$path) {
    $sql    = [System.IO.File]::ReadAllText($path)
    $blocks = Split-SqlBlocks $sql

    $headerPattern = [regex]'(?i)/\*+\s*Object:\s+(\w+)\s+\[(\w+)\]\.\[(\w+)\]'
    $createPattern = [regex]'(?im)^\s*CREATE\s+(TABLE|VIEW|FUNCTION|PROCEDURE|UNIQUE\s+INDEX|NONCLUSTERED\s+INDEX|CLUSTERED\s+INDEX|INDEX)\s+(?:\[?(\w+)\]?\.)?\[?(\w+)\]?'

    $currentOriginalKey = $null

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
            $dobj.OriginalFullName = $currentOriginalKey
            $dobj.RawBody         = $raw
            $dobj.NormalisedBody  = Normalize-Body $raw
            $objects[$currentKey] = $dobj
        }
        $currentKey         = $null
        $currentOriginalKey = $null
        $currentType        = $null
        $currentBlocks.Clear()
    }

    foreach ($block in $blocks) {
        $hm = $headerPattern.Match($block)
        if ($hm.Success) {
            & $flushCurrent
            $currentKey         = "$($hm.Groups[2].Value.ToLower()).$($hm.Groups[3].Value.ToLower())"
            $currentOriginalKey = "$($hm.Groups[2].Value).$($hm.Groups[3].Value)"
            $currentType        = $hm.Groups[1].Value.ToUpper()
            $currentBlocks.Add($block)
            continue
        }

        $cm = $createPattern.Match($block)
        if ($cm.Success) {
            $cmSchema      = if ($cm.Groups[2].Success -and $cm.Groups[2].Value) { $cm.Groups[2].Value } else { 'dbo' }
            $cmName        = $cm.Groups[3].Value
            $cmKey         = "$($cmSchema.ToLower()).$($cmName.ToLower())"
            $cmOriginalKey = "$cmSchema.$cmName"
            $cmType        = $cm.Groups[1].Value.ToUpper() -replace '\s+', '_'

            if (-not $currentKey) {
                # No active object -- start a new one from this CREATE
                $currentKey         = $cmKey
                $currentOriginalKey = $cmOriginalKey
                $currentType        = $cmType
            } elseif ($currentKey -ne $cmKey) {
                # Different object -- flush current and start a new one
                & $flushCurrent
                $currentKey         = $cmKey
                $currentOriginalKey = $cmOriginalKey
                $currentType        = $cmType
            }
            # else: same object (CREATE follows its SSMS header) -- just append
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
# Column parser  (extracts column definitions from CREATE TABLE body)
# ---------------------------------------------------------------------------

function Parse-TableColumns([string]$rawBody) {
    # Extract content between outermost parentheses of CREATE TABLE (...)
    $start = $rawBody.IndexOf('(')
    $end   = $rawBody.LastIndexOf(')')
    if ($start -lt 0 -or $end -le $start) { return @{} }
    $inner = $rawBody.Substring($start + 1, $end - $start - 1)

    # Split by commas that are NOT inside nested parentheses
    $defs   = [System.Collections.Generic.List[string]]::new()
    $depth  = 0
    $current = [System.Text.StringBuilder]::new()
    foreach ($ch in $inner.ToCharArray()) {
        if     ($ch -eq '(') { $depth++; [void]$current.Append($ch) }
        elseif ($ch -eq ')') { $depth--; [void]$current.Append($ch) }
        elseif ($ch -eq ',' -and $depth -eq 0) {
            $t = $current.ToString().Trim()
            if ($t) { [void]$defs.Add($t) }
            [void]$current.Clear()
        } else {
            [void]$current.Append($ch)
        }
    }
    $t = $current.ToString().Trim()
    if ($t) { [void]$defs.Add($t) }

    # Build name -> definition map; skip constraints
    $constraintPattern = [regex]'(?i)^\s*(PRIMARY\s+KEY|UNIQUE|CONSTRAINT|INDEX|FOREIGN\s+KEY|CHECK)'
    $columns = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)

    foreach ($def in $defs) {
        if ($constraintPattern.IsMatch($def)) { continue }
        # Column name is the first token (strip brackets)
        $nameMatch = [regex]::Match($def, '^\s*\[?(\w+)\]?')
        if ($nameMatch.Success) {
            $columns[$nameMatch.Groups[1].Value] = $def.Trim()
        }
    }
    return $columns
}

function Build-AlterTableStatements([DiffObject]$baselineObj, [DiffObject]$currentObj) {
    # Use OriginalFullName for proper casing (CS collation requires exact case)
    $sourceName = if ($currentObj.OriginalFullName) { $currentObj.OriginalFullName } else { $currentObj.FullName }
    $parts  = $sourceName -split '\.'
    $schema = $parts[0]
    $name   = $parts[1]
    $table  = "[$schema].[$name]"

    $baseCols = Parse-TableColumns $baselineObj.RawBody
    $curCols  = Parse-TableColumns $currentObj.RawBody

    $sb = [System.Text.StringBuilder]::new()

    # Added columns
    foreach ($col in $curCols.Keys) {
        if (-not $baseCols.ContainsKey($col)) {
            [void]$sb.AppendLine("ALTER TABLE $table ADD $($curCols[$col]);")
            [void]$sb.AppendLine("GO")
        }
    }

    # Dropped columns
    foreach ($col in $baseCols.Keys) {
        if (-not $curCols.ContainsKey($col)) {
            [void]$sb.AppendLine("ALTER TABLE $table DROP COLUMN [$col];")
            [void]$sb.AppendLine("GO")
        }
    }

    # Modified columns
    foreach ($col in $curCols.Keys) {
        if ($baseCols.ContainsKey($col)) {
            $baseNorm = ($baseCols[$col] -replace '\s+', ' ').Trim().ToLower()
            $curNorm  = ($curCols[$col]  -replace '  \s+', ' ').Trim().ToLower()
            if ($baseNorm -ne $curNorm) {
                [void]$sb.AppendLine("ALTER TABLE $table ALTER COLUMN $($curCols[$col]);")
                [void]$sb.AppendLine("GO")
            }
        }
    }

    if ($sb.Length -eq 0) {
        # Fallback: parser found no column diff (e.g. constraint-only change)
        [void]$sb.AppendLine("-- TODO: Table $table was modified (constraint/index change).")
        [void]$sb.AppendLine("-- Review differences and write ALTER TABLE statements manually.")
        [void]$sb.AppendLine("GO")
    }

    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# DROP statement builder
# ---------------------------------------------------------------------------

function Build-DropStatement([DiffObject]$obj) {
    $typeKw = switch -Wildcard ($obj.ObjectType) {
        'PROCEDURE'           { 'PROCEDURE'; break }
        'STOREDPROCEDURE'     { 'PROCEDURE'; break }   # SSMS header style
        '*FUNCTION*'          { 'FUNCTION';  break }   # covers FUNCTION, INLINE_TABLE-VALUED_FUNCTION, etc.
        'VIEW'                { 'VIEW';      break }
        'TABLE'               { 'TABLE';     break }
        default               { $null;       break }
    }

    # Use OriginalFullName for proper casing (CS collation requires exact case)
    $sourceName = if ($obj.OriginalFullName) { $obj.OriginalFullName } else { $obj.FullName }
    $parts  = $sourceName -split '\.'
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

    # Index: extract table name from ON [schema].[table] in raw body
    $onMatch = [regex]::Match($obj.RawBody, '(?i)\bON\s+\[?(\w+)\]?\.\[?(\w+)\]?')
    if ($onMatch.Success) {
        $tSchema = $onMatch.Groups[1].Value
        $tName   = $onMatch.Groups[2].Value
        # Index name: use the full name from the CREATE statement (may contain dots)
        $ixMatch = [regex]::Match($obj.RawBody, '(?i)CREATE\s+(?:UNIQUE\s+)?(?:NONCLUSTERED\s+|CLUSTERED\s+)?INDEX\s+\[?([\w.]+)\]?')
        $ixName  = if ($ixMatch.Success) { $ixMatch.Groups[1].Value } else { $name }
        return @"
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = '$ixName' AND object_id = OBJECT_ID('[$tSchema].[$tName]'))
    DROP INDEX [$ixName] ON [$tSchema].[$tName];
GO
"@
    }

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
            $alterStatements = Build-AlterTableStatements -baselineObj $baseline[$obj.FullName] -currentObj $obj
            [void]$sb.AppendLine($alterStatements)
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
