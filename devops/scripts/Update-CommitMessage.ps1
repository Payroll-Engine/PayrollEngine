<#
.SYNOPSIS
    Updates the Git commit message from RELEASE_NOTES.md for a repository.

.DESCRIPTION
    Reads the latest section from RELEASE_NOTES.md and writes it to .git/MERGE_MSG,
    which Visual Studio picks up as the default commit message in Git Changes.
    Only processes repositories with uncommitted changes.

.PARAMETER RepoPath
    Path to the Git repository. Defaults to the current directory.

.PARAMETER ReleaseNotesPath
    Path to the RELEASE_NOTES.md file.

.PARAMETER Silent
    Skip confirmation prompt (for bulk mode).

.EXAMPLE
    .\Update-CommitMessage.ps1
    .\Update-CommitMessage.ps1 -RepoPath "C:\Shared\PayrollEngine\Repos\PayrollEngine.Backend"
    .\Update-CommitMessage.ps1 -RepoPath "C:\Repos\Backend" -Silent
#>
param(
    [string]$RepoPath = ".",
    [string]$ReleaseNotesPath = (Join-Path (Resolve-Path "$PSScriptRoot\..\..").Path "RELEASE_NOTES.md"),
    [switch]$Silent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region Helper functions

function Get-LatestSection {
    param([string[]]$Lines)

    $sectionLines = @()
    $inSection = $false

    foreach ($line in $Lines) {
        if ($line -match "^##\s+") {
            if ($inSection) {
                break
            }
            $inSection = $true
            continue
        }
        if ($inSection) {
            $sectionLines += $line
        }
    }

    $text = ($sectionLines -join "`n").Trim()
    return $text
}

#endregion

# --- resolve paths ---
$RepoPath = Resolve-Path $RepoPath
$repoName = Split-Path $RepoPath -Leaf
$gitDir = Join-Path $RepoPath ".git"

if (-not (Test-Path $gitDir)) {
    Write-Warning "[$repoName] no .git directory found - skipping"
    exit 1
}

# --- check for uncommitted changes ---
Push-Location $RepoPath
try {
    $status = git status --porcelain 2>&1
    if (-not $status) {
        Write-Host "[$repoName] clean - no uncommitted changes" -ForegroundColor DarkGray
        exit 0
    }

    $changedFiles = ($status | Measure-Object).Count
    Write-Host "[$repoName] $changedFiles uncommitted change(s)" -ForegroundColor Cyan

    # --- read release notes ---
    if (-not (Test-Path $ReleaseNotesPath)) {
        Write-Warning "[$repoName] RELEASE_NOTES.md not found: $ReleaseNotesPath"
        exit 1
    }

    $lines = Get-Content $ReleaseNotesPath -Encoding UTF8
    $commitMessage = Get-LatestSection $lines

    if (-not $commitMessage) {
        Write-Warning "[$repoName] no section found in RELEASE_NOTES.md"
        exit 1
    }

    # --- display summary ---
    Write-Host ""
    Write-Host "[$repoName] commit message:" -ForegroundColor Yellow
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    Write-Host $commitMessage -ForegroundColor White
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""

    # --- confirmation ---
    if (-not $Silent) {
        $answer = Read-Host "update commit message? [y/N]"
        if ($answer -notin @("y", "Y", "yes", "Yes")) {
            Write-Host "[$repoName] skipped" -ForegroundColor DarkGray
            exit 0
        }
    }

    # --- write .git/MERGE_MSG ---
    $mergeMsgPath = Join-Path $gitDir "MERGE_MSG"
    Set-Content -Path $mergeMsgPath -Value $commitMessage -Encoding UTF8 -NoNewline
    Write-Host "[$repoName] commit message updated (.git/MERGE_MSG)" -ForegroundColor Green
}
finally {
    Pop-Location
}
