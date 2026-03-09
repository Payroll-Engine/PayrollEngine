#Requires -Version 7.0
<#
.SYNOPSIS
    PayrollEngine Release Changelog Management
.DESCRIPTION
    Pre-checks all repos for clean state, collects changelog entries
    since the last release tag, and consolidates them into a root
    changelog and wiki release notes.
.PARAMETER ReposRoot
    Root directory containing all PayrollEngine repositories.
.PARAMETER Mode
    Operation mode: PreCheck, Collect, Consolidate, or Full (all steps).
.PARAMETER Version
    Target release version (e.g. "1.0.0"). Required for Consolidate/Full.
.PARAMETER SinceTag
    Git tag to collect changes from. If omitted, uses the latest tag.
.PARAMETER OutputDir
    Directory for generated changelog files. Defaults to ReposRoot.
.PARAMETER DryRun
    Show what would be done without writing files.
#>

[CmdletBinding()]
param(
    [string]$ReposRoot = (Resolve-Path "$PSScriptRoot\..\..\..").Path,

    [ValidateSet("PreCheck", "Collect", "Consolidate", "Full")]
    [string]$Mode = "Full",

    [string]$Version = "",

    [string]$SinceTag = "",

    [string]$OutputDir = "",

    [switch]$DryRun
)

# ── Configuration ────────────────────────────────────────────────────────────

$RepoConfig = [ordered]@{
    "Common" = @{
        Dir     = "PayrollEngine"
        Display = "General"
        GitHub  = ""
        Group   = "app"
        Order   = 0
    }
    "Backend" = @{
        Dir     = "PayrollEngine.Backend"
        Display = "Backend"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Backend"
        Group   = "app"
        Order   = 1
    }
    "Console" = @{
        Dir     = "Console"
        Display = "Console"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole"
        Group   = "app"
        Order   = 2
    }
    "WebApp" = @{
        Dir     = "PayrollEngine.WebApp"
        Display = "Web App"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.WebApp"
        Group   = "app"
        Order   = 3
    }
    "Client Services" = @{
        Dir     = "PayrollEngine.Client.Services"
        Display = "Client Services"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Client.Services"
        Group   = "library"
        Order   = 10
    }
    "Client Test" = @{
        Dir     = "PayrollEngine.Client.Test"
        Display = "Client Test"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Client.Test"
        Group   = "library"
        Order   = 11
    }
    "Client Scripting" = @{
        Dir     = "PayrollEngine.Client.Scripting"
        Display = "Client Scripting"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Client.Scripting"
        Group   = "library"
        Order   = 12
    }
    "Document" = @{
        Dir     = "PayrollEngine.Document"
        Display = "Document"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Document"
        Group   = "library"
        Order   = 13
    }
    "Serilog" = @{
        Dir     = "PayrollEngine.Serilog"
        Display = "Serilog"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Serilog"
        Group   = "library"
        Order   = 14
    }
    "Client Core" = @{
        Dir     = "PayrollEngine.Client.Core"
        Display = "Client Core"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Client.Core"
        Group   = "library"
        Order   = 15
    }
    "Core" = @{
        Dir     = "PayrollEngine.Core"
        Display = "Core"
        GitHub  = "https://github.com/Payroll-Engine/PayrollEngine.Core"
        Group   = "library"
        Order   = 16
    }
}

$CrossRepoSections = @(
    "CI/CD Pipeline",
    "NuGet Packages",
    "Docker",
    "Release Assets",
    "CI"
)

$RootRepoDir = "PayrollEngine"

$CommitTypes = @{
    "feat"     = @{ Relevant = $true;  Category = "New Features";      Emoji = "✨" }
    "fix"      = @{ Relevant = $true;  Category = "Bug Fixes";         Emoji = "🐛" }
    "perf"     = @{ Relevant = $true;  Category = "Improvements";      Emoji = "⚡" }
    "breaking" = @{ Relevant = $true;  Category = "Breaking Changes";  Emoji = "💥" }
    "security" = @{ Relevant = $true;  Category = "Security";          Emoji = "🔒" }
    "refactor" = @{ Relevant = $false; Category = "Refactoring";       Emoji = "♻️" }
    "docs"     = @{ Relevant = $false; Category = "Documentation";     Emoji = "📝" }
    "test"     = @{ Relevant = $false; Category = "Tests";             Emoji = "🧪" }
    "chore"    = @{ Relevant = $false; Category = "Chores";            Emoji = "🔧" }
    "ci"       = @{ Relevant = $false; Category = "CI/CD";             Emoji = "🏗️" }
    "style"    = @{ Relevant = $false; Category = "Code Style";        Emoji = "💄" }
}

if ([string]::IsNullOrEmpty($OutputDir)) {
    $OutputDir = $ReposRoot
}

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Header([string]$Text) {
    $line = "─" * 60
    Write-Host "`n$line" -ForegroundColor DarkCyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "$line" -ForegroundColor DarkCyan
}

function Write-Status([string]$Label, [string]$Value, [string]$Color = "White") {
    Write-Host "  $($Label.PadRight(20))" -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $Color
}

function Write-Ok([string]$Text) {
    Write-Host "  ✓ $Text" -ForegroundColor Green
}

function Write-Warn([string]$Text) {
    Write-Host "  ⚠ $Text" -ForegroundColor Yellow
}

function Write-Err([string]$Text) {
    Write-Host "  ✗ $Text" -ForegroundColor Red
}

function Get-RepoPath([string]$RepoDir) {
    return Join-Path $ReposRoot $RepoDir
}

function Test-RepoExists([string]$RepoDir) {
    $path = Get-RepoPath $RepoDir
    return (Test-Path (Join-Path $path ".git"))
}

function Get-LatestTag([string]$RepoDir) {
    $path = Get-RepoPath $RepoDir
    Push-Location $path
    try {
        $tag = git describe --tags --abbrev=0 2>$null
        return $tag
    }
    catch {
        return $null
    }
    finally {
        Pop-Location
    }
}

# ── Step 1: Pre-Check ───────────────────────────────────────────────────────

function Invoke-PreCheck {
    Write-Header "Pre-Check: Repository Status"

    $allClean = $true
    $repos = $RepoConfig.Keys

    foreach ($repoKey in $repos) {
        $config = $RepoConfig[$repoKey]
        $repoDir = $config.Dir
        $path = Get-RepoPath $repoDir
        $name = $config.Display

        if (-not (Test-RepoExists $repoDir)) {
            Write-Warn "$name - not found at $path"
            continue
        }

        Push-Location $path
        try {
            $uncommitted = git status --short 2>$null
            $hasUncommitted = -not [string]::IsNullOrWhiteSpace($uncommitted)

            $unpushed = git log "@{u}.." --oneline 2>$null
            $hasUnpushed = -not [string]::IsNullOrWhiteSpace($unpushed)

            $branch = git branch --show-current 2>$null

            if ($hasUncommitted -or $hasUnpushed) {
                $allClean = $false
                Write-Host ""
                Write-Err "$name (branch: $branch)"

                if ($hasUncommitted) {
                    $count = ($uncommitted -split "`n").Count
                    Write-Warn "  $count uncommitted change(s)"
                    $uncommitted -split "`n" | ForEach-Object {
                        Write-Host "      $_" -ForegroundColor DarkYellow
                    }
                }

                if ($hasUnpushed) {
                    $count = ($unpushed -split "`n").Count
                    Write-Warn "  $count unpushed commit(s)"
                    $unpushed -split "`n" | ForEach-Object {
                        Write-Host "      $_" -ForegroundColor DarkYellow
                    }
                }
            }
            else {
                Write-Ok "$name (branch: $branch) - clean"
            }
        }
        finally {
            Pop-Location
        }
    }

    Write-Host ""
    if ($allClean) {
        Write-Ok "All repositories are clean. Ready for release."
    }
    else {
        Write-Err "Some repositories have uncommitted or unpushed changes."
        Write-Err "Please commit and push all changes before generating the changelog."
    }

    return $allClean
}

# ── Step 2: Collect Commits ─────────────────────────────────────────────────

function Parse-ConventionalCommit([string]$Message) {
    if ($Message -match "^(\w+?)(?:\(([^)]*)\))?(!)?\s*:\s*(.+)$") {
        $type = $Matches[1].ToLower()
        $scope = $Matches[2]
        $isBreaking = $Matches[3] -eq "!"
        $description = $Matches[4].Trim()

        if ($isBreaking -and $type -ne "breaking") {
            $type = "breaking"
        }

        return @{
            Type        = $type
            Scope       = $scope
            Description = $description
            IsBreaking  = $isBreaking
            Raw         = $Message
        }
    }

    return @{
        Type        = "other"
        Scope       = ""
        Description = $Message.Trim()
        IsBreaking  = $false
        Raw         = $Message
    }
}

function Get-CommitsSinceTag([string]$RepoDir, [string]$Tag) {
    $path = Get-RepoPath $RepoDir
    Push-Location $path
    try {
        if ([string]::IsNullOrEmpty($Tag)) {
            $log = git log --oneline --no-merges 2>$null
        }
        else {
            $log = git log "$Tag..HEAD" --oneline --no-merges 2>$null
        }

        if ([string]::IsNullOrWhiteSpace($log)) {
            return @()
        }

        $commits = @()
        foreach ($line in ($log -split "`n")) {
            if ($line -match "^([a-f0-9]+)\s+(.+)$") {
                $hash = $Matches[1]
                $message = $Matches[2]
                $parsed = Parse-ConventionalCommit $message
                $commits += @{
                    Hash    = $hash
                    Message = $message
                    Parsed  = $parsed
                }
            }
        }
        return $commits
    }
    finally {
        Pop-Location
    }
}

function Invoke-Collect {
    Write-Header "Collect: Gathering Commits Since Last Release"

    $tag = $SinceTag
    if ([string]::IsNullOrEmpty($tag)) {
        $tag = Get-LatestTag $RootRepoDir
        if ($tag) {
            Write-Status "Latest tag" $tag "Green"
        }
        else {
            Write-Warn "No tags found in root repo. Collecting all commits."
        }
    }
    else {
        Write-Status "Since tag" $tag "Green"
    }

    $allEntries = @()

    foreach ($repoKey in $RepoConfig.Keys) {
        $config = $RepoConfig[$repoKey]
        $repoDir = $config.Dir

        if (-not (Test-RepoExists $repoDir)) {
            Write-Warn "$repoKey - skipped (not found)"
            continue
        }

        $commits = Get-CommitsSinceTag $repoDir $tag

        if ($commits.Count -eq 0) {
            Write-Status $repoKey "no changes" "DarkGray"
            continue
        }

        Write-Status $repoKey "$($commits.Count) commit(s)" "White"

        foreach ($commit in $commits) {
            $parsed = $commit.Parsed
            $typeInfo = $CommitTypes[$parsed.Type]
            $relevant = if ($typeInfo) { $typeInfo.Relevant } else { $false }

            $allEntries += @{
                Repo        = $repoKey
                Hash        = $commit.Hash
                Type        = $parsed.Type
                Scope       = $parsed.Scope
                Description = $parsed.Description
                IsBreaking  = $parsed.IsBreaking
                Relevant    = $relevant
                Raw         = $commit.Message
            }
        }
    }

    Write-Host ""
    Write-Status "Total commits" "$($allEntries.Count)" "Cyan"

    $relevantCount = ($allEntries | Where-Object { $_.Relevant }).Count
    $skippedCount = $allEntries.Count - $relevantCount
    Write-Status "Root-relevant" "$relevantCount" "Green"
    Write-Status "Repo-only" "$skippedCount" "DarkGray"

    return $allEntries
}

# ── Step 3: Consolidate ─────────────────────────────────────────────────────

function Invoke-Consolidate([array]$Entries) {
    if ([string]::IsNullOrEmpty($Version)) {
        Write-Err "Version is required for consolidation. Use -Version parameter."
        return
    }

    Write-Header "Consolidate: Building Release Changelog"

    $date = Get-Date -Format "yyyy-MM-dd"

    Write-Host "`n  Entries proposed for Root Changelog:" -ForegroundColor Cyan
    Write-Host ""

    $relevant = $Entries | Where-Object { $_.Relevant } | Sort-Object { $_.Type }
    $index = 1
    foreach ($entry in $relevant) {
        $typeInfo = $CommitTypes[$entry.Type]
        $emoji = if ($typeInfo) { $typeInfo.Emoji } else { "❓" }
        $color = if ($entry.IsBreaking) { "Red" } else { "White" }

        Write-Host "  [$index] " -NoNewline -ForegroundColor DarkGray
        Write-Host "$emoji " -NoNewline
        Write-Host "$($entry.Type)" -NoNewline -ForegroundColor Yellow
        Write-Host " ($($entry.Repo)): " -NoNewline -ForegroundColor DarkGray
        Write-Host $entry.Description -ForegroundColor $color
        $index++
    }

    Write-Host ""
    Write-Host "  Skipped entries (repo-only):" -ForegroundColor DarkGray
    $skipped = $Entries | Where-Object { -not $_.Relevant }
    foreach ($entry in $skipped) {
        Write-Host "    - $($entry.Type)($($entry.Repo)): $($entry.Description)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "  Options:" -ForegroundColor Cyan
    Write-Host "    [Enter]    Accept selection and generate" -ForegroundColor Gray
    Write-Host "    [e]        Edit - exclude/include entries by number" -ForegroundColor Gray
    Write-Host "    [a]        Abort" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "  Choose"

    if ($choice -eq "a") {
        Write-Warn "Aborted."
        return
    }

    if ($choice -eq "e") {
        Write-Host "  Enter entry numbers to toggle (comma-separated, e.g. 1,3,5):" -ForegroundColor Gray
        $toggleInput = Read-Host "  Toggle"
        $toggleNums = $toggleInput -split "," | ForEach-Object { [int]$_.Trim() }

        $index = 1
        foreach ($entry in $relevant) {
            if ($index -in $toggleNums) {
                $entry.Relevant = -not $entry.Relevant
                $action = if ($entry.Relevant) { "included" } else { "excluded" }
                Write-Status "  #$index" "$action - $($entry.Description)"
            }
            $index++
        }

        Write-Host ""
        Write-Host "  Promote any skipped entry? Enter original commit message substring (or Enter to skip):" -ForegroundColor Gray
        $promoteInput = Read-Host "  Promote"
        if (-not [string]::IsNullOrEmpty($promoteInput)) {
            foreach ($entry in $skipped) {
                if ($entry.Description -like "*$promoteInput*") {
                    $entry.Relevant = $true
                    Write-Ok "Promoted: $($entry.Description)"
                }
            }
        }

        $relevant = $Entries | Where-Object { $_.Relevant }
    }

    function Get-RepoHeading([string]$RepoKey, [string]$HeadingLevel = "-") {
        $config = $RepoConfig[$RepoKey]
        $display = $config.Display
        $github = $config.GitHub
        if ($github) {
            return "$HeadingLevel [$display]($github)"
        }
        return "$HeadingLevel $display"
    }

    $releaseLines = @()

    $appRepos = $RepoConfig.Keys | Where-Object { $RepoConfig[$_].Group -eq "app" } |
        Sort-Object { $RepoConfig[$_].Order }
    $libRepos = $RepoConfig.Keys | Where-Object { $RepoConfig[$_].Group -eq "library" } |
        Sort-Object { $RepoConfig[$_].Order }

    $hasCrossRepo = ($relevant | Where-Object { $_.Repo -eq "Common" }).Count -gt 0
    if ($hasCrossRepo) {
        $commonEntries = $relevant | Where-Object { $_.Repo -eq "Common" }
        $releaseLines += "- General"
        foreach ($entry in $commonEntries) {
            $releaseLines += "  - $($entry.Description)"
        }
        $releaseLines += ""
        $releaseLines += "<!-- TODO: add cross-repo sections (CI/CD Pipeline, NuGet, Docker, etc.) manually -->"
        $releaseLines += ""
    }

    foreach ($repoKey in $appRepos) {
        if ($repoKey -eq "Common") { continue }
        $repoEntries = $relevant | Where-Object { $_.Repo -eq $repoKey }
        if ($repoEntries.Count -eq 0) { continue }

        $releaseLines += Get-RepoHeading $repoKey
        foreach ($entry in $repoEntries) {
            $prefix = switch ($entry.Type) {
                "feat"     { "New feature: " }
                "breaking" { "" }
                "fix"      { "Fixed " }
                "perf"     { "Improved " }
                "security" { "Security: " }
                default    { "" }
            }
            $releaseLines += "  - $prefix$($entry.Description)"
        }
        $releaseLines += ""
    }

    $hasLibEntries = $false
    foreach ($repoKey in $libRepos) {
        if (($relevant | Where-Object { $_.Repo -eq $repoKey }).Count -gt 0) {
            $hasLibEntries = $true
            break
        }
    }

    if ($hasLibEntries) {
        $releaseLines += ""
        $releaseLines += "### Libraries"
        $releaseLines += ""

        foreach ($repoKey in $libRepos) {
            $repoEntries = $relevant | Where-Object { $_.Repo -eq $repoKey }
            if ($repoEntries.Count -eq 0) { continue }

            $releaseLines += Get-RepoHeading $repoKey
            foreach ($entry in $repoEntries) {
                $prefix = switch ($entry.Type) {
                    "feat"     { "New " }
                    "breaking" { "" }
                    "fix"      { "Fixed " }
                    "perf"     { "Improved " }
                    "security" { "Security: " }
                    default    { "" }
                }
                $releaseLines += "  - $prefix$($entry.Description)"
            }
            $releaseLines += ""
        }
    }

    $wikiLines = @()
    $wikiLines += "# Release $Version ($date)"
    $wikiLines += ""

    foreach ($repoKey in $appRepos) {
        $repoEntries = $relevant | Where-Object { $_.Repo -eq $repoKey }
        if ($repoEntries.Count -eq 0) { continue }

        $config = $RepoConfig[$repoKey]
        $wikiLines += "## $($config.Display)"
        $grouped = $repoEntries | Group-Object { $CommitTypes[$_.Type].Category } | Sort-Object Name
        foreach ($group in $grouped) {
            $category = $group.Name
            if ([string]::IsNullOrEmpty($category)) { $category = "Other" }
            if ($grouped.Count -gt 1) {
                $wikiLines += "**$category**"
            }
            foreach ($entry in $group.Group) {
                $wikiLines += "- $($entry.Description)"
            }
        }
        $wikiLines += ""
    }

    if ($hasLibEntries) {
        $wikiLines += "## Libraries"
        $wikiLines += ""
        foreach ($repoKey in $libRepos) {
            $repoEntries = $relevant | Where-Object { $_.Repo -eq $repoKey }
            if ($repoEntries.Count -eq 0) { continue }

            $config = $RepoConfig[$repoKey]
            $wikiLines += "### $($config.Display)"
            foreach ($entry in $repoEntries) {
                $wikiLines += "- $($entry.Description)"
            }
            $wikiLines += ""
        }
    }

    $repoChangelogs = @{}
    foreach ($repoKey in $RepoConfig.Keys) {
        $repoEntries = $Entries | Where-Object { $_.Repo -eq $repoKey }
        if ($repoEntries.Count -eq 0) { continue }

        $lines = @()
        $lines += "## [$Version] - $date"
        $lines += ""
        foreach ($entry in $repoEntries) {
            $lines += "- $($entry.Type): $($entry.Description)"
        }
        $lines += ""
        $repoChangelogs[$repoKey] = $lines
    }

    Write-Header "Generated Output"

    $releaseNotesPath = Join-Path $OutputDir "RELEASE_NOTES-$Version.md"
    $wikiPath = Join-Path $OutputDir "RELEASE-$Version.md"

    if ($DryRun) {
        Write-Host "`n  ── RELEASE_NOTES.md ──" -ForegroundColor Cyan
        $releaseLines | ForEach-Object { Write-Host "  $_" }

        Write-Host "`n  ── Wiki Release Notes ──" -ForegroundColor Cyan
        $wikiLines | ForEach-Object { Write-Host "  $_" }

        foreach ($repoKey in $repoChangelogs.Keys) {
            Write-Host "`n  ── $repoKey Changelog ──" -ForegroundColor Cyan
            $repoChangelogs[$repoKey] | ForEach-Object { Write-Host "  $_" }
        }
    }
    else {
        $releaseLines | Out-File -FilePath $releaseNotesPath -Encoding utf8
        Write-Ok "Release notes: $releaseNotesPath"

        $wikiLines | Out-File -FilePath $wikiPath -Encoding utf8
        Write-Ok "Wiki release notes: $wikiPath"

        foreach ($repoKey in $repoChangelogs.Keys) {
            $config = $RepoConfig[$repoKey]
            $repoChangelogPath = Join-Path (Get-RepoPath $config.Dir) "CHANGELOG-$Version.md"
            $repoChangelogs[$repoKey] | Out-File -FilePath $repoChangelogPath -Encoding utf8
            Write-Ok "$repoKey changelog: $repoChangelogPath"
        }
    }

    Write-Host ""
    Write-Ok "Release $Version changelog consolidation complete."
}

# ── Main ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  PayrollEngine Release Changelog Manager" -ForegroundColor Cyan
Write-Host "  Mode: $Mode | ReposRoot: $ReposRoot" -ForegroundColor DarkGray
if ($DryRun) {
    Write-Host "  *** DRY RUN - no files will be written ***" -ForegroundColor Yellow
}

switch ($Mode) {
    "PreCheck" {
        Invoke-PreCheck | Out-Null
    }
    "Collect" {
        $entries = Invoke-Collect
    }
    "Consolidate" {
        $entries = Invoke-Collect
        Invoke-Consolidate $entries
    }
    "Full" {
        $clean = Invoke-PreCheck
        if (-not $clean) {
            Write-Host ""
            $continue = Read-Host "  Continue anyway? (y/N)"
            if ($continue -ne "y") {
                Write-Warn "Aborted. Please clean up repositories first."
                exit 1
            }
        }
        $entries = Invoke-Collect
        Invoke-Consolidate $entries
    }
}

Write-Host ""
