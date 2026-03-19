<#
.SYNOPSIS
    Composes Create-Model.mysql.sql and Update-Model.mysql.sql from DbVersion.json.

.DESCRIPTION
    Orchestrates the full MySQL DB script composition workflow in one step:

      1. Generate-DbUpdate.mysql.ps1  -- diff History\v<OldVersion>\Create-Model.mysql.sql
                                         against Create-Model.mysql.sql -> delta SQL
      2. Create-Model.mysql.sql       -- replace version comment header
      3. Update-Model.mysql.sql       -- regenerate entirely:
                                           VERSION CHECK  (MySQL SIGNAL SQLSTATE)
                                           delta SQL      (from step 1)
                                           VERSION SET    (INSERT INTO `Version`)

    The Update-Model.mysql.sql file is fully regenerated (not region-patched)
    because MySQL SQL does not support the C# region syntax used by the
    SQL Server counterpart.

.PARAMETER ConfigFile
    Path to DbVersion.json.  Default: DbVersion.json (caller's working dir).
    Expected fields: OldVersion, NewVersion, CreateDescription, UpdateDescription.

.PARAMETER DatabaseDir
    Directory containing Create-Model.mysql.sql, Update-Model.mysql.sql and
    the History sub-folder. Default: caller's working directory.

.PARAMETER ScriptsDir
    Directory containing Generate-DbUpdate.mysql.ps1.
    Default: directory of this script.

.PARAMETER KeepTemp
    Keep the intermediate delta SQL file for inspection.

.PARAMETER DryRun
    Parse and validate all inputs, print a plan, but write nothing.

.EXAMPLE
    # Run from the Database directory
    cd Backend\Database
    ..\..\devops\scripts\Compose-DbScript.mysql.ps1

.EXAMPLE
    # Explicit paths, dry-run first
    Compose-DbScript.mysql.ps1 -ConfigFile DbVersion.json -DatabaseDir . -DryRun
#>

[CmdletBinding()]
param(
    [string] $ConfigFile   = "DbVersion.json",
    [string] $DatabaseDir  = "",
    [string] $ScriptsDir   = "",
    [switch] $KeepTemp,
    [switch] $DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
function Write-Dry([string]$msg)  { Write-Host "  DRY-RUN: $msg" -ForegroundColor Magenta }

function Resolve-AbsPath([string]$path, [string]$base) {
    if (-not $path)                                    { return $base }
    if ([System.IO.Path]::IsPathRooted($path))         { return $path }
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($base, $path))
}

function Split-Version([string]$version) {
    $parts = $version -split '\.'
    if ($parts.Count -ne 3) { throw "Version must be Major.Minor.Sub, got: '$version'" }
    foreach ($p in $parts) {
        if ($p -notmatch '^\d+$') { throw "Version parts must be numeric, got: '$version'" }
    }
    return [PSCustomObject]@{ Major = [int]$parts[0]; Minor = [int]$parts[1]; Sub = [int]$parts[2] }
}

# ---------------------------------------------------------------------------
# MySQL block builders
# ---------------------------------------------------------------------------

function New-MySqlVersionCheckBlock([string]$expectedVersion) {
    $v = Split-Version $expectedVersion
    return @"
-- =============================================================================
-- VERSION CHECK: expected $expectedVersion
-- =============================================================================

DELIMITER `$`$

DROP PROCEDURE IF EXISTS _CheckVersion`$`$
CREATE PROCEDURE _CheckVersion()
BEGIN
    DECLARE v_major INT;
    DECLARE v_minor INT;
    DECLARE v_sub   INT;

    SELECT MajorVersion, MinorVersion, SubVersion
    INTO   v_major, v_minor, v_sub
    FROM   ``Version``
    ORDER  BY MajorVersion DESC, MinorVersion DESC, SubVersion DESC
    LIMIT  1;

    IF v_major <> $($v.Major) OR v_minor <> $($v.Minor) OR v_sub <> $($v.Sub) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = CONCAT(
                'Version mismatch: expected $expectedVersion, found ',
                v_major, '.', v_minor, '.', v_sub);
    END IF;
END`$`$

CALL _CheckVersion()`$`$
DROP PROCEDURE _CheckVersion`$`$

DELIMITER ;

"@
}

function New-MySqlVersionSetBlock([string]$version, [string]$description) {
    # Escape single quotes in description
    $descEscaped = $description -replace "'", "''"
    return @"
-- =============================================================================
-- VERSION RECORD: $version
-- =============================================================================

INSERT INTO ``Version`` (Created, MajorVersion, MinorVersion, SubVersion, Owner, Description)
VALUES (NOW(6),
    $(($version -split '\.')[0]),
    $(($version -split '\.')[1]),
    $(($version -split '\.')[2]),
    CURRENT_USER(),
    '$descEscaped');

SELECT CONCAT('PayrollEngine MySQL schema updated to v$version successfully.') AS Result;

"@
}

function New-MySqlUpdateFileHeader([string]$oldVersion, [string]$newVersion, [string]$description) {
    return @"
-- =============================================================================
-- Update-Model.mysql.sql
-- Migrates PayrollEngine MySQL schema from $oldVersion to $newVersion
-- $description
-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
-- =============================================================================

USE PayrollEngine;

"@
}

# ---------------------------------------------------------------------------
# Create-Model.mysql.sql: update version comment in header
# ---------------------------------------------------------------------------

function Update-CreateModelVersion([string]$sql, [string]$newVersion) {
    # Replace "Schema version: X.Y.Z" line
    return $sql -replace '(?m)(--\s*Schema version:\s*)[\d.]+', "`${1}$newVersion"
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$callerDir   = (Get-Location).Path
$DatabaseDir = Resolve-AbsPath $DatabaseDir $callerDir
$ConfigFile  = Resolve-AbsPath $ConfigFile  $callerDir
$ScriptsDir  = if ($ScriptsDir) { Resolve-AbsPath $ScriptsDir $callerDir } else { $PSScriptRoot }

$createScript   = Join-Path $DatabaseDir "Create-Model.mysql.sql"
$updateScript   = Join-Path $DatabaseDir "Update-Model.mysql.sql"
$generateScript = Join-Path $ScriptsDir  "Generate-DbUpdate.mysql.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Compose-DbScript.mysql" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "  *** DRY-RUN -- no files will be written ***" -ForegroundColor Magenta }

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()
if (-not (Test-Path $ConfigFile))      { $errors += "ConfigFile not found:              $ConfigFile"    }
if (-not (Test-Path $createScript))    { $errors += "Create-Model.mysql.sql not found:  $createScript"  }
if (-not (Test-Path $generateScript))  { $errors += "Generate-DbUpdate.mysql.ps1 not found: $generateScript" }

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

# ---------------------------------------------------------------------------
# Load config
# ---------------------------------------------------------------------------

$cfg               = Get-Content $ConfigFile -Raw | ConvertFrom-Json
$oldVersion        = $cfg.OldVersion
$newVersion        = $cfg.NewVersion
$createDescription = $cfg.CreateDescription
$updateDescription = $cfg.UpdateDescription

foreach ($field in @('OldVersion','NewVersion','CreateDescription','UpdateDescription')) {
    if (-not $cfg.$field) { $errors += "Config missing field: $field" }
}
if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

$historyBaseline = Join-Path $DatabaseDir "History\v$oldVersion\Create-Model.mysql.sql"
if (-not (Test-Path $historyBaseline)) {
    Write-Host "  ERROR: MySQL history baseline not found: $historyBaseline" -ForegroundColor Red
    Write-Host "  INFO:  Copy the previous Create-Model.mysql.sql to History\v$oldVersion\ before running." -ForegroundColor DarkGray
    exit 1
}

Write-Info "Config        : $ConfigFile"
Write-Info "OldVersion    : $oldVersion"
Write-Info "NewVersion    : $newVersion"
Write-Info "DatabaseDir   : $DatabaseDir"
Write-Info "Baseline      : $historyBaseline"

# ---------------------------------------------------------------------------
# Step 1 -- Generate delta SQL
# ---------------------------------------------------------------------------

Write-Section "Step 1/3 -- Generate delta SQL"

$tempDelta = Join-Path $env:TEMP "ComposeDbScript_MySQL_Delta_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

if ($DryRun) {
    Write-Dry "Would run: Generate-DbUpdate.mysql.ps1"
    Write-Dry "  -BaselineFile $historyBaseline"
    Write-Dry "  -CurrentFile  $createScript"
    Write-Dry "  -TargetFile   $tempDelta"
    $deltaContent = "-- [DRY-RUN] delta placeholder`r`n"
} else {
    & $generateScript `
        -BaselineFile $historyBaseline `
        -CurrentFile  $createScript `
        -TargetFile   $tempDelta `
        -ScriptsDir   $ScriptsDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generate-DbUpdate.mysql.ps1 failed (exit $LASTEXITCODE)." -ForegroundColor Red
        exit 1
    }

    if (Test-Path $tempDelta) {
        $deltaContent = [System.IO.File]::ReadAllText($tempDelta)
        Write-Ok "Delta generated: $([Math]::Round((Get-Item $tempDelta).Length / 1KB, 1)) KB"
    } else {
        Write-Warn "No delta file produced (schemas are identical)."
        $deltaContent = "-- No schema changes.`r`n"
    }
}

# ---------------------------------------------------------------------------
# Step 2 -- Update Create-Model.mysql.sql (version comment)
# ---------------------------------------------------------------------------

Write-Section "Step 2/3 -- Update Create-Model.mysql.sql version header"

$createSql = [System.IO.File]::ReadAllText($createScript)
$createSqlNew = Update-CreateModelVersion $createSql $newVersion

if ($DryRun) {
    Write-Dry "Would update schema version comment to $newVersion in Create-Model.mysql.sql"
} else {
    if ($createSql -ne $createSqlNew) {
        [System.IO.File]::WriteAllText($createScript, $createSqlNew, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "Create-Model.mysql.sql: schema version updated to $newVersion"
    } else {
        Write-Warn "Schema version comment not found or already at $newVersion -- no change."
    }
}

# ---------------------------------------------------------------------------
# Step 3 -- Generate Update-Model.mysql.sql
# ---------------------------------------------------------------------------

Write-Section "Step 3/3 -- Generate Update-Model.mysql.sql"

$sb = [System.Text.StringBuilder]::new()

# Header
[void]$sb.Append((New-MySqlUpdateFileHeader $oldVersion $newVersion $updateDescription))

# VERSION CHECK
[void]$sb.Append((New-MySqlVersionCheckBlock $oldVersion))

# SCHEMA CHANGES (delta)
[void]$sb.AppendLine("-- =============================================================================")
[void]$sb.AppendLine("-- SCHEMA CHANGES")
[void]$sb.AppendLine("-- =============================================================================")
[void]$sb.AppendLine("")
[void]$sb.AppendLine($deltaContent.TrimEnd())
[void]$sb.AppendLine("")

# VERSION SET
[void]$sb.Append((New-MySqlVersionSetBlock $newVersion $updateDescription))

$updateContent = $sb.ToString()

if ($DryRun) {
    Write-Dry "Would write Update-Model.mysql.sql ($([Math]::Round($updateContent.Length / 1KB, 1)) KB)"
    Write-Dry "  Sections: VERSION CHECK ($oldVersion) + delta + VERSION SET ($newVersion)"
} else {
    [System.IO.File]::WriteAllText($updateScript, $updateContent, [System.Text.UTF8Encoding]::new($false))
    Write-Ok "Update-Model.mysql.sql written ($([Math]::Round($updateContent.Length / 1KB, 1)) KB)"
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

if (-not $DryRun -and (Test-Path $tempDelta)) {
    if ($KeepTemp) {
        Write-Info "Delta temp file kept: $tempDelta"
    } else {
        Remove-Item $tempDelta -Force
        Write-Info "Delta temp file cleaned up."
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray
if ($DryRun) {
    Write-Host "  DRY-RUN complete -- no files written  |  $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Magenta
} else {
    Write-Host "  DONE  |  $oldVersion -> $newVersion  |  $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
}
exit 0
