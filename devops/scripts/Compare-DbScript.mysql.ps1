<#
.SYNOPSIS
    Compares two MySQL SQL script files and generates a delta (update) script.

.DESCRIPTION
    Parses BaselineFile and CurrentFile into named DDL objects using the
    MySQL $$ delimiter convention and computes the difference:

      Added    -- objects in Current but not in Baseline  -> CREATE statements
      Removed  -- objects in Baseline but not in Current  -> DROP statements
      Modified -- objects in both but with different body  -> DROP + CREATE

    Recognised object types (from CREATE statements):
      PROCEDURE, FUNCTION, TABLE, INDEX (UNIQUE/FULLTEXT/SPATIAL included)

    Both files should be from the same pipeline (Create-Model.mysql.sql or
    a history snapshot).  The generated delta is suitable for inclusion in
    Update-Model.mysql.sql via Compose-DbScript.mysql.ps1.

.PARAMETER BaselineFile
    MySQL SQL file representing the old / source state.

.PARAMETER CurrentFile
    MySQL SQL file representing the new / target state.

.PARAMETER TargetFile
    Path where the delta .sql script is written.  Created or overwritten.

.EXAMPLE
    .\Compare-DbScript.mysql.ps1 `
        -BaselineFile History\v0.9.5\Create-Model.mysql.sql `
        -CurrentFile  Create-Model.mysql.sql `
        -TargetFile   delta.sql
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
function Write-Ok([string]$msg)   { Write-Host "  OK:      $msg" -ForegroundColor Green  }
function Write-Info([string]$msg) { Write-Host "  INFO:    $msg" -ForegroundColor DarkGray }
function Write-Add([string]$msg)  { Write-Host "  ADD:     $msg" -ForegroundColor Cyan   }
function Write-Drop([string]$msg) { Write-Host "  DROP:    $msg" -ForegroundColor Red    }
function Write-Mod([string]$msg)  { Write-Host "  MOD:     $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# MySQL SQL Parser
#
# Strategy:
#   1. Split sections on DELIMITER changes.
#      Between DELIMITER $$ and DELIMITER ; -> use $$ as block separator.
#      Outside (or after DELIMITER ;) -> use ; as statement separator.
#   2. For each block, detect the object type and name from the CREATE statement.
#   3. Normalise body for comparison (strip comments, collapse whitespace).
# ---------------------------------------------------------------------------

class MySqlObject {
    [string]$ObjectType   # PROCEDURE | FUNCTION | TABLE | INDEX
    [string]$Name         # lowercase object name (without schema/backticks)
    [string]$FullKey      # "<type>:<name>" used as dictionary key
    [string]$RawBody      # original text block, used for output
    [string]$NormBody     # normalised text, used for equality check
}

function Strip-BacktickQuotes([string]$name) {
    return $name.Trim().Trim('`')
}

function Normalize-MySqlBody([string]$body) {
    # Remove single-line comments
    $s = $body -replace '--[^\r\n]*', ''
    # Remove multi-line comments
    $s = $s -replace '/\*[\s\S]*?\*/', ''
    # Collapse whitespace
    $s = $s -replace '\s+', ' '
    # Normalise spaces inside parentheses:
    # History files may use multi-line IF ( \n  expr \n  ) style while
    # current files use single-line IF (expr) -- strip the inner spaces.
    $s = $s -replace '\(\s+', '(' -replace '\s+\)', ')'
    return $s.Trim().ToLower()
}

# Detect CREATE object type and name from a SQL block.
# Returns $null if block is not a recognisable DDL object.
function Get-ObjectMeta([string]$block) {
    # PROCEDURE
    if ($block -match '(?i)CREATE\s+(?:DEFINER\s*=\s*\S+\s+)?PROCEDURE\s+`?(\w+)`?\s*\(') {
        return [PSCustomObject]@{ Type = 'PROCEDURE'; Name = $Matches[1].ToLower() }
    }
    # FUNCTION
    if ($block -match '(?i)CREATE\s+(?:DEFINER\s*=\s*\S+\s+)?FUNCTION\s+`?(\w+)`?\s*\(') {
        return [PSCustomObject]@{ Type = 'FUNCTION'; Name = $Matches[1].ToLower() }
    }
    # TABLE (CREATE TABLE or CREATE TABLE IF NOT EXISTS)
    if ($block -match '(?i)CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\(') {
        return [PSCustomObject]@{ Type = 'TABLE'; Name = $Matches[1].ToLower() }
    }
    # INDEX (CREATE [UNIQUE|FULLTEXT|SPATIAL] INDEX)
    if ($block -match '(?i)CREATE\s+(?:UNIQUE\s+|FULLTEXT\s+|SPATIAL\s+)?INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s+ON\s+`?(\w+)`?') {
        $idxName   = $Matches[1].ToLower()
        $tableName = $Matches[2].ToLower()
        return [PSCustomObject]@{ Type = 'INDEX'; Name = "${tableName}.${idxName}" }
    }
    return $null
}

function Parse-MySqlFile([string]$path) {
    $sql = [System.IO.File]::ReadAllText($path)
    $objects = [System.Collections.Generic.Dictionary[string, MySqlObject]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)

    # We process the file in two passes:
    #  Pass A: extract $$ delimited blocks (routines)
    #  Pass B: extract ; delimited statements that are not inside $$ sections

    # --- Pass A: $$ delimited blocks ---
    # Find all DELIMITER $$ ... DELIMITER ; sections
    $delimPattern = [regex]'(?is)DELIMITER\s+\$\$(.*?)DELIMITER\s+;'
    foreach ($delimMatch in $delimPattern.Matches($sql)) {
        $section = $delimMatch.Groups[1].Value
        # Split on $$
        $rawBlocks = $section -split '\$\$'
        foreach ($raw in $rawBlocks) {
            $block = $raw.Trim()
            if ($block.Length -lt 5) { continue }
            # Skip DROP PROCEDURE/FUNCTION IF EXISTS lines (auto-generated)
            if ($block -match '(?i)^\s*DROP\s+(PROCEDURE|FUNCTION)\s+IF\s+EXISTS') { continue }
            # Skip USE / SET / DELIMITER lines
            if ($block -match '(?i)^\s*(USE|SET|DELIMITER|--)\s') { continue }

            $meta = Get-ObjectMeta $block
            if ($null -eq $meta) { continue }

            $obj = [MySqlObject]::new()
            $obj.ObjectType = $meta.Type
            $obj.Name       = $meta.Name
            $obj.FullKey    = "$($meta.Type):$($meta.Name)"
            $obj.RawBody    = $block
            $obj.NormBody   = Normalize-MySqlBody $block
            $objects[$obj.FullKey] = $obj
        }
    }

    # --- Pass B: ; delimited statements outside $$ sections ---
    # Remove all $$ sections first to avoid double-parsing
    $sqlOutside = $delimPattern.Replace($sql, '')
    # Split on ; (skip empty)
    $stmts = $sqlOutside -split ';'
    foreach ($raw in $stmts) {
        $stmt = $raw.Trim()
        if ($stmt.Length -lt 5) { continue }
        # Skip comments-only, USE, SET, DELIMITER
        if ($stmt -match '(?i)^\s*(--|USE\s|SET\s|DELIMITER\s|CREATE\s+DATABASE|INSERT\s+INTO\s+`?Version`?)') { continue }

        $meta = Get-ObjectMeta $stmt
        if ($null -eq $meta) { continue }

        $obj = [MySqlObject]::new()
        $obj.ObjectType = $meta.Type
        $obj.Name       = $meta.Name
        $obj.FullKey    = "$($meta.Type):$($meta.Name)"
        $obj.RawBody    = $stmt
        $obj.NormBody   = Normalize-MySqlBody $stmt
        # Don't overwrite a routine already found in pass A
        if (-not $objects.ContainsKey($obj.FullKey)) {
            $objects[$obj.FullKey] = $obj
        }
    }

    return $objects
}

# ---------------------------------------------------------------------------
# DROP statement builder for MySQL
# ---------------------------------------------------------------------------

function Build-MySqlDrop([MySqlObject]$obj) {
    $name = $obj.Name
    switch ($obj.ObjectType) {
        'PROCEDURE' { return "DROP PROCEDURE IF EXISTS ``$name``;" }
        'FUNCTION'  { return "DROP FUNCTION IF EXISTS ``$name``;"  }
        'TABLE'     { return "DROP TABLE IF EXISTS ``$name``;"     }
        'INDEX'     {
            # name is "table.index"
            $parts = $name -split '\.'
            if ($parts.Count -eq 2) {
                return "DROP INDEX IF EXISTS ``$($parts[1])`` ON ``$($parts[0])``;"
            }
            return "-- NOTE: manual DROP required for INDEX $name"
        }
        default     { return "-- NOTE: manual DROP required for $($obj.ObjectType) $name" }
    }
}

# ---------------------------------------------------------------------------
# CREATE wrapper for routines (needs DELIMITER $$)
# Tables/Indexes are emitted as-is with trailing ;
# ---------------------------------------------------------------------------

function Build-MySqlCreate([MySqlObject]$obj) {
    switch ($obj.ObjectType) {
        { $_ -in 'PROCEDURE','FUNCTION' } {
            return "DELIMITER `$`$`r`n$(($obj.RawBody).TrimEnd())`$`$`r`nDELIMITER ;"
        }
        default {
            $body = $obj.RawBody.TrimEnd().TrimEnd(';')
            return "$body;"
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Compare-DbScript.mysql" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# Resolve relative paths
$callerDir = (Get-Location).Path
foreach ($varName in 'BaselineFile','CurrentFile','TargetFile') {
    $val = (Get-Variable $varName).Value
    if (-not [System.IO.Path]::IsPathRooted($val)) {
        Set-Variable $varName ([System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $val)))
    }
}

Write-Section "Input Files"
foreach ($f in @($BaselineFile, $CurrentFile)) {
    if (-not (Test-Path $f)) {
        Write-Host "  ERROR: File not found: $f" -ForegroundColor Red; exit 1
    }
}
Write-Info "Baseline : $BaselineFile ($([Math]::Round((Get-Item $BaselineFile).Length / 1KB, 1)) KB)"
Write-Info "Current  : $CurrentFile ($([Math]::Round((Get-Item $CurrentFile).Length / 1KB, 1)) KB)"

Write-Section "Parsing"
$baseline = Parse-MySqlFile $BaselineFile
$current  = Parse-MySqlFile $CurrentFile
Write-Info "Baseline objects : $($baseline.Count)"
Write-Info "Current  objects : $($current.Count)"

# ---------------------------------------------------------------------------
# Diff
# ---------------------------------------------------------------------------

Write-Section "Diff"

$added     = [System.Collections.Generic.List[MySqlObject]]::new()
$removed   = [System.Collections.Generic.List[MySqlObject]]::new()
$modified  = [System.Collections.Generic.List[MySqlObject]]::new()
$unchanged = 0

foreach ($key in $current.Keys) {
    if (-not $baseline.ContainsKey($key)) {
        $added.Add($current[$key]); Write-Add $key
    } elseif ($current[$key].NormBody -ne $baseline[$key].NormBody) {
        $modified.Add($current[$key]); Write-Mod $key
    } else {
        $unchanged++
    }
}
foreach ($key in $baseline.Keys) {
    if (-not $current.ContainsKey($key)) {
        $removed.Add($baseline[$key]); Write-Drop $key
    }
}

Write-Info "Added    : $($added.Count)"
Write-Info "Removed  : $($removed.Count)"
Write-Info "Modified : $($modified.Count)"
Write-Info "Equal    : $unchanged"

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
[void]$sb.AppendLine("-- MySQL Delta Update Script")
[void]$sb.AppendLine("-- Baseline : $(Split-Path $BaselineFile -Leaf)")
[void]$sb.AppendLine("-- Current  : $(Split-Path $CurrentFile  -Leaf)")
[void]$sb.AppendLine("-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine("-- Changes  : +$($added.Count) added / -$($removed.Count) removed / ~$($modified.Count) modified")
[void]$sb.AppendLine("-- ============================================================")
[void]$sb.AppendLine("")

# 1. Drop removed
if ($removed.Count -gt 0) {
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Removed objects ($($removed.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")
    # Drop order: routines before tables
    $dropOrder = $removed | Sort-Object {
        switch ($_.ObjectType) {
            'PROCEDURE' { 1 } 'FUNCTION' { 2 } 'INDEX' { 3 } 'TABLE' { 5 } default { 4 }
        }
    }
    foreach ($obj in $dropOrder) {
        [void]$sb.AppendLine($(Build-MySqlDrop $obj))
        [void]$sb.AppendLine("")
    }
}

# 2. Drop modified (before re-create)
if ($modified.Count -gt 0) {
    $modRoutines = @($modified | Where-Object { $_.ObjectType -in 'PROCEDURE','FUNCTION' })
    $modTables   = @($modified | Where-Object { $_.ObjectType -eq 'TABLE' })
    $modIndexes  = @($modified | Where-Object { $_.ObjectType -eq 'INDEX' })

    if ($modRoutines.Count -gt 0 -or $modIndexes.Count -gt 0) {
        [void]$sb.AppendLine("-- ------------------------------------------------------------")
        [void]$sb.AppendLine("-- Modified objects -- drop before re-create ($($modified.Count))")
        [void]$sb.AppendLine("-- ------------------------------------------------------------")
        [void]$sb.AppendLine("")
        foreach ($obj in ($modRoutines + $modIndexes)) {
            [void]$sb.AppendLine($(Build-MySqlDrop $obj))
        }
        [void]$sb.AppendLine("")
    }

    if ($modTables.Count -gt 0) {
        [void]$sb.AppendLine("-- ------------------------------------------------------------")
        [void]$sb.AppendLine("-- Modified tables -- manual ALTER TABLE required ($($modTables.Count))")
        [void]$sb.AppendLine("-- ------------------------------------------------------------")
        [void]$sb.AppendLine("")
        foreach ($obj in $modTables) {
            [void]$sb.AppendLine("-- TODO: Table ``$($obj.Name)`` was modified.")
            [void]$sb.AppendLine("-- Review column differences and write ALTER TABLE ... ADD/MODIFY/DROP COLUMN.")
            [void]$sb.AppendLine("")
        }
    }
}

# 3. Create added
if ($added.Count -gt 0) {
    # Create order: tables before routines before indexes
    $createOrder = $added | Sort-Object {
        switch ($_.ObjectType) {
            'TABLE' { 1 } 'FUNCTION' { 2 } 'PROCEDURE' { 3 } 'INDEX' { 5 } default { 4 }
        }
    }
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Added objects ($($added.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")
    foreach ($obj in $createOrder) {
        [void]$sb.AppendLine($(Build-MySqlCreate $obj))
        [void]$sb.AppendLine("")
    }
}

# 4. Re-create modified routines and indexes
$modRecreate = @($modified | Where-Object { $_.ObjectType -in 'PROCEDURE','FUNCTION','INDEX' })
if ($modRecreate.Count -gt 0) {
    $createOrder = $modRecreate | Sort-Object {
        switch ($_.ObjectType) {
            'FUNCTION' { 1 } 'PROCEDURE' { 2 } 'INDEX' { 3 } default { 4 }
        }
    }
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("-- Modified objects -- re-create ($($modRecreate.Count))")
    [void]$sb.AppendLine("-- ------------------------------------------------------------")
    [void]$sb.AppendLine("")
    foreach ($obj in $createOrder) {
        [void]$sb.AppendLine($(Build-MySqlCreate $obj))
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
