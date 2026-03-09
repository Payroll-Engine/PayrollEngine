<#
.SYNOPSIS
    Generates a database update (delta) script from two SQL script files.

.DESCRIPTION
    Orchestrates the full update-script generation pipeline:

      1. Format BaselineFile  ->  <WorkDir>\Baseline.Formatted.sql
      2. Format CurrentFile   ->  <WorkDir>\Current.Formatted.sql
      3. Compare both         ->  TargetFile  (via Compare-DbScript)

    Both input files are formatted before comparison so that whitespace,
    comment and object-order differences do not produce false positives.

    The generated script contains:
      - DROP statements for removed objects
      - CREATE statements for added objects
      - DROP + CREATE for modified programmable objects (SP, function, view)
      - TODO comments for modified tables (manual ALTER TABLE required)

    Requires Format-DbScript.ps1 and Compare-DbScript.ps1 in the same directory
    as this script (or override with -ScriptsDir).

.PARAMETER BaselineFile
    SQL script representing the OLD / source schema state.
    Typically the previously released ModelCreate.sql (or a DB export snapshot).

.PARAMETER CurrentFile
    SQL script representing the NEW / target schema state.
    Typically the updated ModelCreate.sql.

.PARAMETER TargetFile
    Path where the delta update script is written.  Created or overwritten.
    Defaults to ModelUpdate.sql in the current directory.

.PARAMETER ScriptsDir
    Directory containing Format-DbScript.ps1 and Compare-DbScript.ps1.
    Defaults to the directory of this script.

.PARAMETER WorkDir
    Directory for intermediate formatted files.
    Defaults to a timestamped sub-folder of $env:TEMP.

.PARAMETER KeepTemp
    Keep the intermediate formatted files after completion.
    By default they are deleted.

.EXAMPLE
    # Minimal - output goes to .\ModelUpdate.sql
    .\Generate-DbUpdate.ps1 `
        -BaselineFile .\Snapshot_v095.sql `
        -CurrentFile  .\ModelCreate.sql

.EXAMPLE
    # Explicit output path
    .\Generate-DbUpdate.ps1 `
        -BaselineFile OldSchema\ModelCreate.sql `
        -CurrentFile  NewSchema\ModelCreate.sql `
        -TargetFile   Releases\v0.9.6\ModelUpdate.sql

.EXAMPLE
    # Keep intermediate formatted files for inspection
    .\Generate-DbUpdate.ps1 `
        -BaselineFile ModelCreate.v095.sql `
        -CurrentFile  ModelCreate.sql `
        -TargetFile   ModelUpdate.sql `
        -KeepTemp
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $BaselineFile,
    [Parameter(Mandatory)][string] $CurrentFile,
    [string] $TargetFile  = "ModelUpdate.sql",
    [string] $ScriptsDir  = "",
    [string] $WorkDir     = "",
    [switch] $KeepTemp
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

function Resolve-AbsPath([string]$path, [string]$base) {
    if ([System.IO.Path]::IsPathRooted($path)) { return $path }
    return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($base, $path))
}

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

$callerDir = (Get-Location).Path

$BaselineFile = Resolve-AbsPath $BaselineFile $callerDir
$CurrentFile  = Resolve-AbsPath $CurrentFile  $callerDir
$TargetFile   = Resolve-AbsPath $TargetFile   $callerDir

if (-not $ScriptsDir) {
    $ScriptsDir = $PSScriptRoot
}
$ScriptsDir = Resolve-AbsPath $ScriptsDir $callerDir

$formatScript  = Join-Path $ScriptsDir "Format-DbScript.ps1"
$compareScript = Join-Path $ScriptsDir "Compare-DbScript.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Generate-DbUpdate" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()

if (-not (Test-Path $BaselineFile)) { $errors += "BaselineFile not found: $BaselineFile" }
if (-not (Test-Path $CurrentFile))  { $errors += "CurrentFile not found: $CurrentFile"   }
if (-not (Test-Path $formatScript)) { $errors += "Format-DbScript.ps1 not found: $formatScript"  }
if (-not (Test-Path $compareScript)){ $errors += "Compare-DbScript.ps1 not found: $compareScript" }

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

$bInfo = Get-Item $BaselineFile
$cInfo = Get-Item $CurrentFile
Write-Info "Baseline  : $BaselineFile ($([Math]::Round($bInfo.Length / 1KB, 1)) KB)"
Write-Info "Current   : $CurrentFile ($([Math]::Round($cInfo.Length / 1KB, 1)) KB)"
Write-Info "Target    : $TargetFile"
Write-Info "ScriptsDir: $ScriptsDir"

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
Write-Info "WorkDir   : $WorkDir"

$baselineFormatted = Join-Path $WorkDir "Baseline.Formatted.sql"
$currentFormatted  = Join-Path $WorkDir "Current.Formatted.sql"

# ---------------------------------------------------------------------------
# Step 1 - Format baseline
# ---------------------------------------------------------------------------

Write-Section "Step 1 / 3  -  Format Baseline"

& $formatScript -SourceFile $BaselineFile -TargetFile $baselineFormatted
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Format-DbScript failed for BaselineFile (exit $LASTEXITCODE)." -ForegroundColor Red
    exit 1
}
Write-Ok "Formatted: $baselineFormatted"

# ---------------------------------------------------------------------------
# Step 2 - Format current
# ---------------------------------------------------------------------------

Write-Section "Step 2 / 3  -  Format Current"

& $formatScript -SourceFile $CurrentFile -TargetFile $currentFormatted
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Format-DbScript failed for CurrentFile (exit $LASTEXITCODE)." -ForegroundColor Red
    exit 1
}
Write-Ok "Formatted: $currentFormatted"

# ---------------------------------------------------------------------------
# Step 3 - Compare and generate delta script
# ---------------------------------------------------------------------------

Write-Section "Step 3 / 3  -  Compare and Generate Delta"

$targetDir = Split-Path $TargetFile -Parent
if ($targetDir -and -not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

& $compareScript -BaselineFile $baselineFormatted -CurrentFile $currentFormatted -TargetFile $TargetFile
$compareExit = $LASTEXITCODE

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

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray

if ($compareExit -eq 0 -and (Test-Path $TargetFile)) {
    $outInfo  = Get-Item $TargetFile
    $elapsedS = $elapsed.TotalSeconds.ToString('F1')
    $sizeKB   = [Math]::Round($outInfo.Length / 1KB, 1)
    Write-Host ("  DONE  |  " + $elapsedS + "s  |  " + $sizeKB + " KB") -ForegroundColor Green
    Write-Host "  Output: $TargetFile" -ForegroundColor White
} elseif ($compareExit -eq 0) {
    $elapsedS = $elapsed.TotalSeconds.ToString('F1')
    Write-Host ("  DONE  |  " + $elapsedS + "s  |  No differences found") -ForegroundColor Green
} else {
    Write-Host ("  FAILED  |  Compare-DbScript exit code: " + $compareExit) -ForegroundColor Red
    exit $compareExit
}

exit 0
