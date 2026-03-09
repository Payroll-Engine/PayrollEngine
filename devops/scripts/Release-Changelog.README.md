# Release-Changelog

Collects Git commits across all PayrollEngine repositories and consolidates them
into release notes and per-repository changelogs.

## Overview

`Release-Changelog.ps1` automates the changelog generation pipeline for a
PayrollEngine release. It verifies that all repositories are clean, gathers
commits since the last tag, and builds a structured `RELEASE_NOTES.md` draft
and a wiki release page.

Requires **PowerShell 7+**.

## Modes

| Mode | What It Does |
|------|-------------|
| `PreCheck` | Verifies all repos have no uncommitted or unpushed changes |
| `Collect` | Gathers commits since the last tag across all repos; prints a summary |
| `Consolidate` | Runs Collect, then builds and writes release notes (interactive) |
| `Full` | PreCheck + Collect + Consolidate (default) |

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-ReposRoot` | No | Three levels up from script | Root folder containing all PayrollEngine repos |
| `-Mode` | No | `Full` | Operation mode: `PreCheck`, `Collect`, `Consolidate`, `Full` |
| `-Version` | Consolidate/Full | — | Target release version (e.g. `1.0.0`) |
| `-SinceTag` | No | Latest tag in root repo | Git tag to collect changes from |
| `-OutputDir` | No | `ReposRoot` | Directory for generated files |
| `-DryRun` | No | `false` | Preview output without writing files |

## Usage Examples

```powershell
# Full pipeline for a release
.\Release-Changelog.ps1 -Version "1.0.0"

# Verify repos are clean before release
.\Release-Changelog.ps1 -Mode PreCheck

# Collect commits since a specific tag (dry run preview)
.\Release-Changelog.ps1 -Version "1.0.0" -SinceTag "v0.9.5" -DryRun

# Consolidate only (skips PreCheck)
.\Release-Changelog.ps1 -Mode Consolidate -Version "1.0.0"

# Custom repos root
.\Release-Changelog.ps1 -Version "1.0.0" -ReposRoot "D:\Repos"
```

## Repositories Covered

| Key | Repository | Group |
|-----|-----------|-------|
| Common | `PayrollEngine` | App |
| Backend | `PayrollEngine.Backend` | App |
| Console | `PayrollEngine.PayrollConsole` | App |
| WebApp | `PayrollEngine.WebApp` | App |
| Client Services | `PayrollEngine.Client.Services` | Library |
| Client Test | `PayrollEngine.Client.Test` | Library |
| Client Scripting | `PayrollEngine.Client.Scripting` | Library |
| Document | `PayrollEngine.Document` | Library |
| Serilog | `PayrollEngine.Serilog` | Library |
| Client Core | `PayrollEngine.Client.Core` | Library |
| Core | `PayrollEngine.Core` | Library |

## Commit Convention

Commits are parsed using the Conventional Commits format:

```
type(scope)!: description
```

| Type | Relevant for Root? | Category |
|------|--------------------|---------|
| `feat` | ✓ | New Features |
| `fix` | ✓ | Bug Fixes |
| `perf` | ✓ | Improvements |
| `breaking` / `!` | ✓ | Breaking Changes |
| `security` | ✓ | Security |
| `refactor` | ✗ | Refactoring |
| `docs` | ✗ | Documentation |
| `test` | ✗ | Tests |
| `chore` | ✗ | Chores |
| `ci` | ✗ | CI/CD |

Non-conventional commits are collected but not classified as relevant.
Relevant commits appear in the root changelog; all commits appear in per-repo changelogs.

## Generated Files

| File | Description |
|------|-------------|
| `RELEASE_NOTES-<version>.md` | Draft for the `RELEASE_NOTES.md` Features section |
| `RELEASE-<version>.md` | Wiki-style release page |
| `<RepoDir>/CHANGELOG-<version>.md` | Per-repository changelog (all commit types) |

Generated files are drafts — review and integrate them manually into the actual
`RELEASE_NOTES.md` and wiki before releasing.

## Interactive Consolidation

During the `Consolidate` step the script displays all relevant commits and prompts:

```
  [Enter]    Accept selection and generate
  [e]        Edit – exclude/include entries by number
  [a]        Abort
```

The `[e]` option allows toggling individual entries and promoting skipped
(repo-only) commits to the root changelog before writing files.

## Notes

- `RELEASE_NOTES.md` is the single source of truth for release text in the
  CI/CD pipeline — generated drafts must be integrated into it manually.
- The `Common` repo group (root `PayrollEngine` repo) maps to the **General**
  section; cross-repo topics (CI/CD Pipeline, NuGet, Docker) are flagged with a
  `TODO` comment in the generated draft.
- If no tags are found in the root repo, the script collects all commits.
