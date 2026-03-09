<#
.SYNOPSIS
    Composes Create-Model.sql and Update-Model.sql from DbVersion.json.

.DESCRIPTION
    Orchestrates the full DB script composition workflow in one step:

      1. Generate-DbUpdate.ps1  -- diff History\<OldVersion>\Create-Model.sql
                                   against Create-Model.sql -> delta SQL
      2. Create-Model.sql       -- replace #region VERSION_SET with NewVersion
      3. Update-Model.sql       -- replace all three regions:
                                     #region VERSION_CHECK  <- OldVersion
                                     #region DB_SCRIPTS     <- delta SQL
                                     #region VERSION_SET    <- NewVersion

    All modifications are made in-place. Intermediate temp files are deleted
    automatically unless -KeepTemp is specified.

    Region syntax in SQL files (C# region style):
        -- #region REGION_NAME
        ...content...
        -- #endregion REGION_NAME

    Recognised region names:
        DATABASE        (Create-Model.sql only, not modified by this script)
        DB_SCRIPTS      (Create-Model.sql: read for diff baseline;
                         Update-Model.sql: replaced with delta)
        VERSION_CHECK   (Update-Model.sql: replaced with OldVersion check)
        VERSION_SET     (both files: replaced with NewVersion insert)

.PARAMETER ConfigFile
    Path to DbVersion.json. Default: DbVersion.json (caller's working dir).
    Expected fields: OldVersion, NewVersion, CreateDescription, UpdateDescription.

.PARAMETER DatabaseDir
    Directory containing Create-Model.sql, Update-Model.sql and the History
    sub-folder. Default: caller's working directory.

.PARAMETER ScriptsDir
    Directory containing Generate-DbUpdate.ps1.
    Default: directory of this script.

.PARAMETER KeepTemp
    Keep the intermediate delta SQL file for inspection.

.PARAMETER DryRun
    Parse and validate all inputs, print a plan, but write nothing.

.EXAMPLE
    # Run from the Database directory
    cd Backend\Database
    ..\..\devops\scripts\Compose-DbScript.ps1

.EXAMPLE
    # Explicit paths
    Compose-DbScript.ps1 -ConfigFile DbVersion.json -DatabaseDir . -DryRun

.EXAMPLE
    # Keep temp delta file for inspection
    Compose-DbScript.ps1 -KeepTemp
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

function Write-Ok([string]$msg)   { Write-Host "  OK:      $msg" -ForegroundColor Green   }
function Write-Info([string]$msg) { Write-Host "  INFO:    $msg" -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow  }
function Write-Dry([string]$msg)  { Write-Host "  DRY-RUN: $msg" -ForegroundColor Magenta }

function Resolve-AbsPath([string]$path, [string]$base) {
    if (-not $path)                                    { return $base }
    if ([System.IO.Path]::IsPathRooted($path))         { return $path }
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($base, $path))
}

# ---------------------------------------------------------------------------
# Region helpers
# ---------------------------------------------------------------------------

function Get-RegionContent([string]$sql, [string]$regionName) {
    $start = "-- #region $regionName"
    $end   = "-- #endregion $regionName"
    $si    = $sql.IndexOf($start)
    $ei    = $sql.IndexOf($end)
    if ($si -lt 0) { throw "Region '$regionName' start marker not found." }
    if ($ei -lt 0) { throw "Region '$regionName' end marker not found."   }
    if ($ei -le $si) { throw "Region '$regionName': end marker before start marker." }
    # Content between end-of-start-line and start-of-end-line
    $afterStart = $si + $start.Length
    $nlPos      = $sql.IndexOf("`n", $afterStart)
    $contentStart = if ($nlPos -ge 0) { $nlPos + 1 } else { $afterStart }
    return $sql.Substring($contentStart, $ei - $contentStart)
}

function Set-RegionContent([string]$sql, [string]$regionName, [string]$newContent) {
    $start = "-- #region $regionName"
    $end   = "-- #endregion $regionName"
    $si    = $sql.IndexOf($start)
    $ei    = $sql.IndexOf($end)
    if ($si -lt 0) { throw "Region '$regionName' start marker not found." }
    if ($ei -lt 0) { throw "Region '$regionName' end marker not found."   }
    if ($ei -le $si) { throw "Region '$regionName': end marker before start marker." }

    $afterStart   = $si + $start.Length
    $nlPos        = $sql.IndexOf("`n", $afterStart)
    $contentStart = if ($nlPos -ge 0) { $nlPos + 1 } else { $afterStart }

    $before = $sql.Substring(0, $contentStart)
    $after  = $sql.Substring($ei)

    # Ensure newContent ends with a newline before the end marker
    $body = $newContent.TrimEnd("`r", "`n") + "`r`n"
    return $before + $body + $after
}

# ---------------------------------------------------------------------------
# SQL block builders  (matching Compose-DbScript v1 style)
# ---------------------------------------------------------------------------

function Split-Version([string]$version) {
    $parts = $version -split '\.'
    if ($parts.Count -ne 3) { throw "Version must be Major.Minor.Sub, got: '$version'" }
    foreach ($p in $parts) {
        if ($p -notmatch '^\d+$') { throw "Version parts must be numeric, got: '$version'" }
    }
    return [PSCustomObject]@{ Major = [int]$parts[0]; Minor = [int]$parts[1]; Sub = [int]$parts[2] }
}

function New-VersionCheckBlock([string]$expectedVersion) {
    $v = Split-Version $expectedVersion
    return @"
USE [PayrollEngine];
GO

SET XACT_ABORT ON
GO

DECLARE @MajorVersion int, @MinorVersion int, @SubVersion int
SELECT TOP 1
    @MajorVersion = MajorVersion,
    @MinorVersion = MinorVersion,
    @SubVersion   = SubVersion
FROM dbo.[Version]
ORDER BY MajorVersion DESC, MinorVersion DESC, SubVersion DESC

IF @MajorVersion <> $($v.Major) OR @MinorVersion <> $($v.Minor) OR @SubVersion <> $($v.Sub) BEGIN
    DECLARE @ActualVersion NVARCHAR(20) =
        CAST(ISNULL(@MajorVersion, -1) AS NVARCHAR) + '.' +
        CAST(ISNULL(@MinorVersion, -1) AS NVARCHAR) + '.' +
        CAST(ISNULL(@SubVersion,   -1) AS NVARCHAR)
    RAISERROR('Version mismatch: expected $expectedVersion, found %s', 16, 1, @ActualVersion)
    SET NOEXEC ON   -- suppress all subsequent batches incl. BEGIN TRANSACTION
END
GO
"@
}

function New-VersionSetBlock([string]$version, [string]$description) {
    $v = Split-Version $version
    return @"
DECLARE @errorID int
INSERT INTO dbo.[Version] (
    MajorVersion,
    MinorVersion,
    SubVersion,
    [Owner],
    [Description] )
VALUES (
    $($v.Major),
    $($v.Minor),
    $($v.Sub),
    CURRENT_USER,
    '$description' )
SET @errorID = @@ERROR
IF ( @errorID <> 0 ) BEGIN
    PRINT 'Error while updating the Payroll Engine database version.'
END
ELSE BEGIN
    PRINT 'Payroll Engine database version successfully updated to release $version'
END
GO

COMMIT TRANSACTION
GO

SET NOEXEC OFF   -- re-enable execution (in case VERSION_CHECK set it ON)
GO
"@
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$callerDir   = (Get-Location).Path
$DatabaseDir = Resolve-AbsPath $DatabaseDir $callerDir
$ConfigFile  = Resolve-AbsPath $ConfigFile  $callerDir
$ScriptsDir  = if ($ScriptsDir) { Resolve-AbsPath $ScriptsDir $callerDir } else { $PSScriptRoot }

$createScript    = Join-Path $DatabaseDir "Create-Model.sql"
$updateScript    = Join-Path $DatabaseDir "Update-Model.sql"
$generateScript  = Join-Path $ScriptsDir  "Generate-DbUpdate.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Compose-DbScript" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "  *** DRY-RUN -- no files will be written ***" -ForegroundColor Magenta }

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()
if (-not (Test-Path $ConfigFile))      { $errors += "ConfigFile not found:      $ConfigFile"    }
if (-not (Test-Path $createScript))    { $errors += "Create-Model.sql not found: $createScript" }
if (-not (Test-Path $updateScript))    { $errors += "Update-Model.sql not found: $updateScript" }
if (-not (Test-Path $generateScript))  { $errors += "Generate-DbUpdate.ps1 not found: $generateScript" }

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

$historyBaseline = Join-Path $DatabaseDir "History\v$oldVersion\Create-Model.sql"
if (-not (Test-Path $historyBaseline)) {
    Write-Host "  ERROR: History baseline not found: $historyBaseline" -ForegroundColor Red
    exit 1
}

Write-Info "Config        : $ConfigFile"
Write-Info "OldVersion    : $oldVersion"
Write-Info "NewVersion    : $newVersion"
Write-Info "DatabaseDir   : $DatabaseDir"
Write-Info "Baseline      : $historyBaseline"
Write-Info "ScriptsDir    : $ScriptsDir"

# ---------------------------------------------------------------------------
# Step 1 -- Generate delta SQL  (History\vX.Y.Z\Create-Model.sql -> Create-Model.sql)
# ---------------------------------------------------------------------------

Write-Section "Step 1/3 -- Generate DB_SCRIPTS delta"

$tempDelta = Join-Path $env:TEMP "ComposeDbScript_Delta_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"

if ($DryRun) {
    Write-Dry "Would run: Generate-DbUpdate.ps1"
    Write-Dry "  -BaselineFile $historyBaseline"
    Write-Dry "  -CurrentFile  $createScript"
    Write-Dry "  -TargetFile   $tempDelta"
    $deltaContent = "-- [DRY-RUN] delta placeholder`r`nGO`r`n"
} else {
    & $generateScript `
        -BaselineFile $historyBaseline `
        -CurrentFile  $createScript `
        -TargetFile   $tempDelta `
        -ScriptsDir   $ScriptsDir

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generate-DbUpdate.ps1 failed (exit $LASTEXITCODE)." -ForegroundColor Red
        exit 1
    }

    if (Test-Path $tempDelta) {
        $deltaContent = [System.IO.File]::ReadAllText($tempDelta)
        $deltaInfo    = Get-Item $tempDelta
        Write-Ok "Delta generated: $tempDelta ($([Math]::Round($deltaInfo.Length / 1KB, 1)) KB)"
    } else {
        Write-Warn "No delta file produced (schemas are identical)."
        $deltaContent = "-- No schema changes.`r`nGO`r`n"
    }
}

# ---------------------------------------------------------------------------
# Step 2 -- Update Create-Model.sql  (#region VERSION_SET)
# ---------------------------------------------------------------------------

Write-Section "Step 2/3 -- Update Create-Model.sql #region VERSION_SET"

$createSql     = [System.IO.File]::ReadAllText($createScript)
$newVersionSet = New-VersionSetBlock -Version $newVersion -Description $createDescription
$createSql     = Set-RegionContent $createSql "VERSION_SET" $newVersionSet

if ($DryRun) {
    Write-Dry "Would write Create-Model.sql with VERSION_SET = $newVersion"
    Write-Dry "  Description: $createDescription"
} else {
    [System.IO.File]::WriteAllText($createScript, $createSql, [System.Text.UTF8Encoding]::new($false))
    Write-Ok "Create-Model.sql updated."
}

# ---------------------------------------------------------------------------
# Step 3 -- Update Update-Model.sql  (all three regions)
# ---------------------------------------------------------------------------

Write-Section "Step 3/3 -- Update Update-Model.sql (VERSION_CHECK / DB_SCRIPTS / VERSION_SET)"

$updateSql = [System.IO.File]::ReadAllText($updateScript)

# 3a. VERSION_CHECK
$newVersionCheck = New-VersionCheckBlock -ExpectedVersion $oldVersion
$updateSql = Set-RegionContent $updateSql "VERSION_CHECK" $newVersionCheck
Write-Info "VERSION_CHECK  -> expects $oldVersion"

# 3b. DB_SCRIPTS -- prepend USE + BEGIN TRANSACTION so the delta runs in the correct DB context
#     transactionally: DDL is rolled back automatically on any error (XACT_ABORT ON)
$useStatement = "BEGIN TRANSACTION`r`nGO`r`n`r`nUSE [PayrollEngine];`r`nGO`r`n"
$updateSql = Set-RegionContent $updateSql "DB_SCRIPTS" ($useStatement + $deltaContent)
Write-Info "DB_SCRIPTS     -> delta ($([Math]::Round($deltaContent.Length / 1KB, 1)) KB)"

# 3c. VERSION_SET
$newUpdateVersionSet = New-VersionSetBlock -Version $newVersion -Description $updateDescription
$updateSql = Set-RegionContent $updateSql "VERSION_SET" $newUpdateVersionSet
Write-Info "VERSION_SET    -> $newVersion"

if ($DryRun) {
    Write-Dry "Would write Update-Model.sql with all three regions updated."
} else {
    [System.IO.File]::WriteAllText($updateScript, $updateSql, [System.Text.UTF8Encoding]::new($false))
    Write-Ok "Update-Model.sql updated."
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

if (-not $DryRun -and (Test-Path $tempDelta)) {
    if ($KeepTemp) {
        Write-Info "Delta temp file kept: $tempDelta"
    } else {
        Remove-Item $tempDelta -Force
        Write-Info "Delta temp file deleted."
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
