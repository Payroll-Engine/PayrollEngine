<#
.SYNOPSIS
    Generates a MySQL database update (delta) script from two SQL script files.

.DESCRIPTION
    Compares two Create-Model.mysql.sql files (baseline vs current) and produces
    a delta SQL script containing:
      - DROP statements for removed objects
      - CREATE statements for added objects
      - DROP + CREATE for modified routines and indexes
      - TODO comments for modified tables (manual ALTER TABLE required)

    Unlike the SQL Server equivalent (Generate-DbUpdate.ps1), no Format step is
    needed because MySQL script files do not have SSMS-style object headers or
    dependency-ordering issues.

    Requires Compare-DbScript.mysql.ps1 in the same directory as this script
    (or override with -ScriptsDir).

.PARAMETER BaselineFile
    MySQL SQL script representing the OLD / source schema state.
    Typically History\v<OldVersion>\Create-Model.mysql.sql.

.PARAMETER CurrentFile
    MySQL SQL script representing the NEW / target schema state.
    Typically Create-Model.mysql.sql in the Database directory.

.PARAMETER TargetFile
    Path where the delta update script is written.  Created or overwritten.
    Defaults to delta.mysql.sql in the current directory.

.PARAMETER ScriptsDir
    Directory containing Compare-DbScript.mysql.ps1.
    Defaults to the directory of this script.

.EXAMPLE
    .\Generate-DbUpdate.mysql.ps1 `
        -BaselineFile History\v0.9.5\Create-Model.mysql.sql `
        -CurrentFile  Create-Model.mysql.sql `
        -TargetFile   delta.mysql.sql

.EXAMPLE
    # From the Database directory
    cd Backend\Database
    ..\..\devops\scripts\Generate-DbUpdate.mysql.ps1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $BaselineFile,
    [Parameter(Mandatory)][string] $CurrentFile,
    [string] $TargetFile  = "delta.mysql.sql",
    [string] $ScriptsDir  = ""
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

if (-not $ScriptsDir) { $ScriptsDir = $PSScriptRoot }
$ScriptsDir    = Resolve-AbsPath $ScriptsDir $callerDir
$compareScript = Join-Path $ScriptsDir "Compare-DbScript.mysql.ps1"

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Generate-DbUpdate.mysql" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

Write-Section "Validation"

$errors = @()
if (-not (Test-Path $BaselineFile))  { $errors += "BaselineFile not found: $BaselineFile"  }
if (-not (Test-Path $CurrentFile))   { $errors += "CurrentFile not found: $CurrentFile"    }
if (-not (Test-Path $compareScript)) { $errors += "Compare-DbScript.mysql.ps1 not found: $compareScript" }

if ($errors.Count -gt 0) {
    foreach ($e in $errors) { Write-Host "  ERROR: $e" -ForegroundColor Red }
    exit 1
}

Write-Info "Baseline  : $BaselineFile ($([Math]::Round((Get-Item $BaselineFile).Length / 1KB, 1)) KB)"
Write-Info "Current   : $CurrentFile ($([Math]::Round((Get-Item $CurrentFile).Length / 1KB, 1)) KB)"
Write-Info "Target    : $TargetFile"
Write-Info "ScriptsDir: $ScriptsDir"

# ---------------------------------------------------------------------------
# Compare and generate delta
# Note: No Format step needed for MySQL -- files are plain SQL without
# SSMS-style headers or dependency-ordering issues.
# ---------------------------------------------------------------------------

Write-Section "Compare and Generate Delta"

$targetDir = Split-Path $TargetFile -Parent
if ($targetDir -and -not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

& $compareScript `
    -BaselineFile $BaselineFile `
    -CurrentFile  $CurrentFile `
    -TargetFile   $TargetFile

$compareExit = $LASTEXITCODE

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray

if ($compareExit -eq 0 -and (Test-Path $TargetFile)) {
    $outInfo = Get-Item $TargetFile
    Write-Host ("  DONE  |  $($elapsed.TotalSeconds.ToString('F1'))s  |  $([Math]::Round($outInfo.Length / 1KB, 1)) KB") -ForegroundColor Green
    Write-Host "  Output: $TargetFile" -ForegroundColor White
} elseif ($compareExit -eq 0) {
    Write-Host ("  DONE  |  $($elapsed.TotalSeconds.ToString('F1'))s  |  No differences found") -ForegroundColor Green
} else {
    Write-Host ("  FAILED  |  Compare-DbScript.mysql.ps1 exit code: $compareExit") -ForegroundColor Red
    exit $compareExit
}

exit 0
