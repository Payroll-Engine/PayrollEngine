<#
.SYNOPSIS
    Generates a complete database update script from DbVersion.json.

.DESCRIPTION
    Reads DbVersion.json to determine source/target versions, then:

      1. Format History\v<OldVersion>\Create-Model.sql  ->  Baseline.Formatted.sql
      2. Format Create-Model.sql                        ->  Current.Formatted.sql
      3. Compare both                                   ->  raw delta SQL
      4. Wrap delta with VERSION_CHECK header and VERSION_SET footer
      5. Write the complete, self-contained Update-Model.sql

    The generated Update-Model.sql is ready to run as-is:
      - VERSION_CHECK validates the DB is on OldVersion; aborts via SET NOEXEC ON if not
      - Delta DDL runs inside BEGIN TRANSACTION with XACT_ABORT ON (auto-rollback on error)
      - TODO comments in the delta mark tables requiring manual ALTER TABLE statements
      - VERSION_SET inserts the NewVersion record and commits the transaction

    Requires Format-DbScript.ps1 and Compare-DbScript.ps1 in the same directory
    as this script (or override with -ScriptsDir).

.PARAMETER DatabaseDir
    Directory containing DbVersion.json, Create-Model.sql, Update-Model.sql and History\.
    Defaults to the caller's working directory.

.PARAMETER ConfigFile
    Path to DbVersion.json. Defaults to DbVersion.json in DatabaseDir.

.PARAMETER ScriptsDir
    Directory containing Format-DbScript.ps1 and Compare-DbScript.ps1.
    Defaults to the directory of this script.

.PARAMETER BaselineFile
    Override the baseline SQL file (normally auto-detected from History\v<OldVersion>\Create-Model.sql).

.PARAMETER CurrentFile
    Override the current SQL file (normally Create-Model.sql in DatabaseDir).

.PARAMETER TargetFile
    Override the output path (normally Update-Model.sql in DatabaseDir).

.PARAMETER WorkDir
    Directory for intermediate formatted files.
    Defaults to a timestamped sub-folder of $env:TEMP.

.PARAMETER KeepTemp
    Keep the intermediate formatted files after completion.

.PARAMETER DryRun
    Parse and validate all inputs, print plan, write nothing.

.EXAMPLE
    # Run from the Database directory (all defaults)
    cd Backend\Database
    ..\..\devops\scripts\Generate-DbUpdate.ps1

.EXAMPLE
    # Explicit paths
    Generate-DbUpdate.ps1 `
        -DatabaseDir C:\...\Database `
        -ScriptsDir  C:\...\devops\scripts

.EXAMPLE
    # Preview without writing anything
    Generate-DbUpdate.ps1 -DryRun

.EXAMPLE
    # Keep intermediate formatted files for inspection
    Generate-DbUpdate.ps1 -KeepTemp
#>

[CmdletBinding()]
param(
    [string] $DatabaseDir  = "",
    [string] $ConfigFile   = "",
    [string] $ScriptsDir   = "",
    [string] $BaselineFile = "",
    [string] $CurrentFile  = "",
    [string] $TargetFile   = "",
    [string] $WorkDir      = "",
    [switch] $KeepTemp,
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

function New-VersionCheckBlock([string]$expectedVersion) {
    $v = Split-Version $expectedVersion
    return @"
USE [PayrollEngine];
GO

SET XACT_ABORT ON
GO

-- Guard: abort immediately if the schema is not present at all
IF OBJECT_ID('dbo.Version') IS NULL BEGIN
    RAISERROR('Schema not found: dbo.Version does not exist. Run Create-Model.sql first.', 16, 1)
    SET NOEXEC ON   -- suppress all subsequent batches
END
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
$ScriptsDir  = if ($ScriptsDir) { Resolve-AbsPath $ScriptsDir $callerDir } else { $PSScriptRoot }
$ConfigFile  = if ($ConfigFile) { Resolve-AbsPath $ConfigFile $callerDir } else { Join-Path $DatabaseDir "DbVersion.json" }

$formatScript  = Join-Path $ScriptsDir "Format-DbScript.ps1"
$compareScript = Join-Path $ScriptsDir "Compare-DbScript.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Generate-DbUpdate" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "  *** DRY-RUN -- no files will be written ***" -ForegroundColor Magenta }

# ---------------------------------------------------------------------------
# Validate scripts
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()
if (-not (Test-Path $formatScript))  { $errors += "Format-DbScript.ps1 not found: $formatScript"   }
if (-not (Test-Path $compareScript)) { $errors += "Compare-DbScript.ps1 not found: $compareScript" }
if (-not (Test-Path $ConfigFile))    { $errors += "DbVersion.json not found: $ConfigFile"           }

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

if (-not $BaselineFile) { $BaselineFile = Join-Path $DatabaseDir "History\v$oldVersion\Create-Model.sql" }
if (-not $CurrentFile)  { $CurrentFile  = Join-Path $DatabaseDir "Create-Model.sql" }
if (-not $TargetFile)   { $TargetFile   = Join-Path $DatabaseDir "Update-Model.sql" }

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
# Work directory
# ---------------------------------------------------------------------------

$cleanupWork = $false
if (-not $WorkDir) {
    $WorkDir     = Join-Path $env:TEMP "GenerateDbUpdate_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $cleanupWork = -not $KeepTemp
}
$WorkDir = Resolve-AbsPath $WorkDir $callerDir

if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}
Write-Info "WorkDir    : $WorkDir"

$baselineFormatted = Join-Path $WorkDir "Baseline.Formatted.sql"
$currentFormatted  = Join-Path $WorkDir "Current.Formatted.sql"
$rawDelta          = Join-Path $WorkDir "Delta.Raw.sql"

# ---------------------------------------------------------------------------
# Step 1 - Format baseline
# ---------------------------------------------------------------------------

Write-Section "Step 1 / 3  -  Format Baseline"

if ($DryRun) {
    Write-Dry "Would format: $BaselineFile"
} else {
    & $formatScript -SourceFile $BaselineFile -TargetFile $baselineFormatted
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Format-DbScript failed for BaselineFile (exit $LASTEXITCODE)." -ForegroundColor Red
        exit 1
    }
    Write-Ok "Formatted: $baselineFormatted"
}

# ---------------------------------------------------------------------------
# Step 2 - Format current
# ---------------------------------------------------------------------------

Write-Section "Step 2 / 3  -  Format Current"

if ($DryRun) {
    Write-Dry "Would format: $CurrentFile"
} else {
    & $formatScript -SourceFile $CurrentFile -TargetFile $currentFormatted
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Format-DbScript failed for CurrentFile (exit $LASTEXITCODE)." -ForegroundColor Red
        exit 1
    }
    Write-Ok "Formatted: $currentFormatted"
}

# ---------------------------------------------------------------------------
# Step 3 - Compare and assemble final Update-Model.sql
# ---------------------------------------------------------------------------

Write-Section "Step 3 / 3  -  Compare and Assemble Update-Model.sql"

if ($DryRun) {
    Write-Dry "Would compare formatted files and write: $TargetFile"
    Write-Dry "  VERSION_CHECK : expects $oldVersion"
    Write-Dry "  DB_SCRIPTS    : delta DDL inside BEGIN TRANSACTION"
    Write-Dry "  VERSION_SET   : inserts $newVersion, commits"
} else {
    $targetDir = Split-Path $TargetFile -Parent
    if ($targetDir -and -not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    & $compareScript -BaselineFile $baselineFormatted -CurrentFile $currentFormatted -TargetFile $rawDelta
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Compare-DbScript failed (exit $LASTEXITCODE)." -ForegroundColor Red
        exit 1
    }

    $deltaContent = if (Test-Path $rawDelta) {
        [System.IO.File]::ReadAllText($rawDelta)
    } else {
        Write-Warn "No delta file produced (schemas are identical)."
        "-- No schema changes.`r`nGO`r`n"
    }

    # Assemble the complete Update-Model.sql
    $versionCheck = New-VersionCheckBlock -ExpectedVersion $oldVersion
    $dbScripts    = "BEGIN TRANSACTION`r`nGO`r`n`r`nUSE [PayrollEngine];`r`nGO`r`n`r`n" + $deltaContent
    $versionSet   = New-VersionSetBlock   -Version $newVersion -Description $updateDescription

    $output = $versionCheck + $dbScripts + "`r`n" + $versionSet

    [System.IO.File]::WriteAllText($TargetFile, $output, [System.Text.UTF8Encoding]::new($false))

    $outInfo = Get-Item $TargetFile
    Write-Ok "Update-Model.sql written: $TargetFile ($([Math]::Round($outInfo.Length / 1KB, 1)) KB)"
    Write-Info "VERSION_CHECK : expects $oldVersion"
    Write-Info "VERSION_SET   : inserts $newVersion"
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

if ($KeepTemp) {
    Write-Info "Temp files kept in: $WorkDir"
} elseif ($cleanupWork -and (Test-Path $WorkDir)) {
    Remove-Item -Path $WorkDir -Recurse -Force
    Write-Info "Temp files cleaned up"
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
