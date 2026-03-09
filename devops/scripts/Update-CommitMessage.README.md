# Update-CommitMessage

Pre-fills the Git commit message from the latest section of `RELEASE_NOTES.md`
for use in Visual Studio's Git Changes window.

## Overview

`Update-CommitMessage.ps1` reads the most recent `##`-headed section from
`RELEASE_NOTES.md` and writes it to `.git/MERGE_MSG`. Visual Studio picks up
this file as the default commit message in the **Git Changes** panel, eliminating
the need to copy-paste release notes manually before each commit.

The script only acts on repositories that have uncommitted changes — clean
repositories are skipped automatically.

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-RepoPath` | No | `.` (current directory) | Path to the Git repository |
| `-ReleaseNotesPath` | No | `<RepoRoot>\RELEASE_NOTES.md` | Path to `RELEASE_NOTES.md` |
| `-Silent` | No | `false` | Skip the confirmation prompt (useful for bulk scripts) |

## Usage Examples

```powershell
# Update commit message for the current directory's repo
.\Update-CommitMessage.ps1

# Update a specific repository
.\Update-CommitMessage.ps1 -RepoPath "C:\Shared\PayrollEngine\Repos\PayrollEngine.Backend"

# Silent mode – no confirmation prompt (for automation / bulk use)
.\Update-CommitMessage.ps1 -RepoPath "C:\Shared\PayrollEngine\Repos\PayrollEngine.Backend" -Silent

# Use a custom RELEASE_NOTES.md path
.\Update-CommitMessage.ps1 `
    -RepoPath          "C:\Repos\PayrollEngine.Backend" `
    -ReleaseNotesPath  "C:\Repos\PayrollEngine\RELEASE_NOTES.md"
```

## How It Works

1. Checks the target repository for uncommitted changes via `git status --porcelain`
2. If the repo is clean, exits silently (exit code `0`)
3. Reads `RELEASE_NOTES.md` and extracts the content of the first `##`-headed section
4. Displays the extracted message for review
5. Prompts for confirmation (unless `-Silent`)
6. Writes the message to `.git/MERGE_MSG`

Visual Studio reads `.git/MERGE_MSG` and pre-fills the commit message box on the
next open of the Git Changes panel.

## RELEASE_NOTES.md Structure

The script extracts the content between the first `##` heading and the next `##`
heading (or end of file). Example:

```markdown
### Features        ← top-level heading (### or #), ignored as boundary marker
                     (the script looks for ##-level sections)

## v1.0.0 Changes   ← this section is extracted

- Backend
  - New payrun preview endpoint
  - Fixed rate limiting
- Libraries
  - Client Services
    - Improved performance

## v0.9.6 Changes   ← extraction stops here
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (message written, or repo was clean) |
| `1` | Error — no `.git` directory, `RELEASE_NOTES.md` not found, or no section found |
