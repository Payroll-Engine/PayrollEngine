<#
.SYNOPSIS
    Generates a MySQL database update (delta) script from DbVersion.json or
    from explicit file paths.

.DESCRIPTION
    Compares two Create-Model.mysql.sql files (baseline vs current) and produces
    a self-contained Update-Model.mysql.sql containing:
      - VERSION_CHECK block (SIGNAL if DB is not at OldVersion)
      - DROP statements for removed objects
      - CREATE statements for added objects
      - DROP + CREATE for modified routines and indexes
      - TODO comments for modified tables (manual ALTER TABLE required)
      - VERSION_SET block (INSERT into Version table)

    Unlike the SQL Server equivalent (Generate-DbUpdate.ps1), no Format step is
    needed because MySQL script files do not have SSMS-style object headers.

    Requires Compare-DbScript.mysql.ps1 in the same directory as this script
    (or override with -ScriptsDir).

.PARAMETER DatabaseDir
    Directory containing DbVersion.json, Create-Model.mysql.sql and History\.
    When provided, all file paths are auto-detected from DbVersion.json.
    Defaults to the caller's working directory.

.PARAMETER ConfigFile
    Path to DbVersion.json. Defaults to DbVersion.json in DatabaseDir.

.PARAMETER BaselineFile
    Override the baseline SQL file (normally auto-detected from
    History\v<OldVersion>\Create-Model.mysql.sql).

.PARAMETER CurrentFile
    Override the current SQL file (normally Create-Model.mysql.sql in DatabaseDir).

.PARAMETER TargetFile
    Override the output path (normally Update-Model.mysql.sql in DatabaseDir).

.PARAMETER ScriptsDir
    Directory containing Compare-DbScript.mysql.ps1.
    Defaults to the directory of this script.

.PARAMETER DryRun
    Parse and validate all inputs, print plan, write nothing.

.EXAMPLE
    # From the Database directory (all defaults via DbVersion.json)
    cd Backend\Database
    ..\..\devops\scripts\Generate-DbUpdate.mysql.ps1

.EXAMPLE
    # Explicit DatabaseDir
    Generate-DbUpdate.mysql.ps1 -DatabaseDir C:\...\Database

.EXAMPLE
    # Explicit files (legacy / standalone)
    Generate-DbUpdate.mysql.ps1 `
        -BaselineFile History\v0.9.6\Create-Model.mysql.sql `
        -CurrentFile  Create-Model.mysql.sql `
        -TargetFile   Update-Model.mysql.sql

.EXAMPLE
    # Preview without writing
    Generate-DbUpdate.mysql.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [string] $DatabaseDir  = "",
    [string] $ConfigFile   = "",
    [string] $BaselineFile = "",
    [string] $CurrentFile  = "",
    [string] $TargetFile   = "",
    [string] $ScriptsDir   = "",
    [switch] $DryRun
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
function Write-Dry([string]$msg)  { Write-Host "  DRY-RUN: $msg" -ForegroundColor Magenta }

function Resolve-AbsPath([string]$path, [string]$base) {
    if (-not $path)                                { return $base }
    if ([System.IO.Path]::IsPathRooted($path))     { return $path }
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

function New-MySqlVersionCheckBlock([string]$expectedVersion) {
    $v = Split-Version $expectedVersion
    # $d holds the MySQL statement delimiter; single-quoted to prevent PS interpolation
    $d = '$$'
    return @"
-- =============================================================================
-- VERSION CHECK
-- Guard: abort if the schema is not at version $expectedVersion
-- =============================================================================

DROP PROCEDURE IF EXISTS _PE_VersionCheck;

DELIMITER $d

CREATE PROCEDURE _PE_VersionCheck()
BEGIN
    DECLARE v_major INT DEFAULT NULL;
    DECLARE v_minor INT DEFAULT NULL;
    DECLARE v_sub   INT DEFAULT NULL;
    DECLARE v_msg   VARCHAR(200);

    -- Abort if the Version table does not exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'Version'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Schema not found: Version table does not exist. Run Create-Model.mysql.sql first.';
    END IF;

    SELECT MajorVersion, MinorVersion, SubVersion
    INTO v_major, v_minor, v_sub
    FROM ``Version``
    ORDER BY MajorVersion DESC, MinorVersion DESC, SubVersion DESC
    LIMIT 1;

    IF v_major <> $($v.Major) OR v_minor <> $($v.Minor) OR v_sub <> $($v.Sub) THEN
        SET v_msg = CONCAT('Version mismatch: expected $expectedVersion, found ',
                           IFNULL(v_major, -1), '.', IFNULL(v_minor, -1), '.', IFNULL(v_sub, -1));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;
END$d

DELIMITER ;

CALL _PE_VersionCheck();
DROP PROCEDURE IF EXISTS _PE_VersionCheck;

"@
}

function New-MySqlVersionSetBlock([string]$version, [string]$description) {
    $v = Split-Version $version
    return @"
-- =============================================================================
-- VERSION SET
-- =============================================================================

INSERT INTO ``Version`` (Created, MajorVersion, MinorVersion, SubVersion, Owner, Description)
VALUES (NOW(6), $($v.Major), $($v.Minor), $($v.Sub), CURRENT_USER(), '$description (MySQL)');

SELECT CONCAT('PayrollEngine MySQL schema updated to v$version successfully.') AS Result;
"@
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$callerDir   = (Get-Location).Path
$DatabaseDir = Resolve-AbsPath $DatabaseDir $callerDir
$ScriptsDir  = if ($ScriptsDir) { Resolve-AbsPath $ScriptsDir $callerDir } else { $PSScriptRoot }
$ConfigFile  = if ($ConfigFile) { Resolve-AbsPath $ConfigFile $callerDir } else { Join-Path $DatabaseDir "DbVersion.json" }

$compareScript = Join-Path $ScriptsDir "Compare-DbScript.mysql.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Generate-DbUpdate.mysql" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "  *** DRY-RUN -- no files will be written ***" -ForegroundColor Magenta }

# ---------------------------------------------------------------------------
# Validate helper scripts
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()
if (-not (Test-Path $compareScript)) { $errors += "Compare-DbScript.mysql.ps1 not found: $compareScript" }
if (-not (Test-Path $ConfigFile))    { $errors += "DbVersion.json not found: $ConfigFile" }

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

# ---------------------------------------------------------------------------
# Load DbVersion.json
# ---------------------------------------------------------------------------

$cfg               = Get-Content $ConfigFile -Raw | ConvertFrom-Json
$oldVersion        = $cfg.OldVersion
$newVersion        = $cfg.NewVersion
$updateDescription = $cfg.UpdateDescription

foreach ($field in @('OldVersion','NewVersion','UpdateDescription')) {
    if (-not $cfg.$field) { $errors += "Config missing field: $field" }
}
if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

# ---------------------------------------------------------------------------
# Resolve file paths (auto-detect unless overridden)
# ---------------------------------------------------------------------------

if (-not $BaselineFile) { $BaselineFile = Join-Path $DatabaseDir "History\v$oldVersion\Create-Model.mysql.sql" }
if (-not $CurrentFile)  { $CurrentFile  = Join-Path $DatabaseDir "Create-Model.mysql.sql" }
if (-not $TargetFile)   { $TargetFile   = Join-Path $DatabaseDir "Update-Model.mysql.sql" }

$BaselineFile = Resolve-AbsPath $BaselineFile $callerDir
$CurrentFile  = Resolve-AbsPath $CurrentFile  $callerDir
$TargetFile   = Resolve-AbsPath $TargetFile   $callerDir

if (-not (Test-Path $BaselineFile)) { $errors += "BaselineFile not found: $BaselineFile" }
if (-not (Test-Path $CurrentFile))  { $errors += "CurrentFile not found: $CurrentFile"   }

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

$bInfo = Get-Item $BaselineFile
$cInfo = Get-Item $CurrentFile
Write-Info "Config     : $ConfigFile"
Write-Info "OldVersion : $oldVersion"
Write-Info "NewVersion : $newVersion"
Write-Info "Baseline   : $BaselineFile ($([Math]::Round($bInfo.Length / 1KB, 1)) KB)"
Write-Info "Current    : $CurrentFile ($([Math]::Round($cInfo.Length / 1KB, 1)) KB)"
Write-Info "Target     : $TargetFile"
Write-Info "ScriptsDir : $ScriptsDir"

# ---------------------------------------------------------------------------
# Compare and generate delta
# ---------------------------------------------------------------------------

Write-Section "Compare and Generate Delta"

if ($DryRun) {
    Write-Dry "Would compare baseline vs current and write: $TargetFile"
    Write-Dry "  VERSION_CHECK : expects $oldVersion"
    Write-Dry "  DB_SCRIPTS    : delta DDL"
    Write-Dry "  VERSION_SET   : inserts $newVersion"
} else {
    $rawDelta  = [System.IO.Path]::GetTempFileName()
    $targetDir = Split-Path $TargetFile -Parent
    if ($targetDir -and -not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    & $compareScript `
        -BaselineFile $BaselineFile `
        -CurrentFile  $CurrentFile `
        -TargetFile   $rawDelta

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Compare-DbScript.mysql.ps1 failed (exit $LASTEXITCODE)." -ForegroundColor Red
        Remove-Item $rawDelta -Force -ErrorAction SilentlyContinue
        exit 1
    }

    $deltaContent = if (Test-Path $rawDelta) {
        [System.IO.File]::ReadAllText($rawDelta)
    } else {
        Write-Warn "No delta file produced (schemas are identical)."
        "-- No schema changes.`r`n"
    }
    Remove-Item $rawDelta -Force -ErrorAction SilentlyContinue

    # Assemble the complete Update-Model.mysql.sql
    $versionCheck = New-MySqlVersionCheckBlock -ExpectedVersion $oldVersion
    $versionSet   = New-MySqlVersionSetBlock   -Version $newVersion -Description $updateDescription

    $output = $versionCheck + $deltaContent + "`r`n" + $versionSet

    [System.IO.File]::WriteAllText($TargetFile, $output, [System.Text.UTF8Encoding]::new($false))

    $outInfo = Get-Item $TargetFile
    Write-Ok "Update-Model.mysql.sql written: $TargetFile ($([Math]::Round($outInfo.Length / 1KB, 1)) KB)"
    Write-Info "VERSION_CHECK : expects $oldVersion"
    Write-Info "VERSION_SET   : inserts $newVersion"
}

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

$elapsed  = (Get-Date) - $startTime
$elapsedS = $elapsed.TotalSeconds.ToString('F1')
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray

if ($DryRun) {
    Write-Host "  DRY-RUN complete -- no files written  |  $elapsedS`s" -ForegroundColor Magenta
} else {
    Write-Host "  DONE  |  $oldVersion -> $newVersion  |  $elapsedS`s" -ForegroundColor Green
    Write-Host "  Output: $TargetFile" -ForegroundColor White
    Write-Host "  Next:   Review TODO comments and add ALTER TABLE statements" -ForegroundColor Yellow
}

exit 0
