# Update-BreakingChanges

Detects breaking changes in uncommitted code across all PayrollEngine APIs and
documents them in `RELEASE_NOTES.md`.

## Overview

`Update-BreakingChanges.ps1` compares the current (uncommitted) state of each
repository against the last Git commit. It inspects four API surfaces, reports
breaking changes to the console, and optionally appends them to `RELEASE_NOTES.md`
in the correct section.

No external diff tools are required — the script uses the .NET SDK and PowerShell only.

## Checks Performed

| Step | Surface | Method |
|------|---------|--------|
| 0 | Swagger generation | Rebuilds `swagger.json` via Swashbuckle CLI from Backend build |
| 1 | REST API (Provider) | `swagger.json` diff — endpoints, parameters, schemas, response codes |
| 2 | Backend API Models | Public .NET API surface diff via `MetadataLoadContext` |
| 3 | Scripting API (Regulator) | Public .NET API surface diff |
| 4 | Client Services (Automator) | Public .NET API surface diff |

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-ReposRoot` | No | Three levels up from script | Root folder containing all PayrollEngine repos |
| `-BaselineRef` | No | `HEAD` | Git ref to compare against |
| `-ReportPath` | No | — | Optional path for a Markdown report file |
| `-SwaggerJsonPath` | No | — | Path to a pre-generated `swagger.json` (skips Swashbuckle CLI build) |
| `-ConfirmReleaseNotes` | No | `false` | Prompt for confirmation before updating `RELEASE_NOTES.md` |
| `-SkipReleaseNotes` | No | `false` | Skip `RELEASE_NOTES.md` update entirely |

## Usage Examples

```powershell
# Default – compare against HEAD, auto-update RELEASE_NOTES.md
.\Update-BreakingChanges.ps1

# Compare against a specific tag
.\Update-BreakingChanges.ps1 -BaselineRef "v0.9.0"

# Write a Markdown report in addition to console output
.\Update-BreakingChanges.ps1 -ReportPath ".\breaking-changes.md"

# Prompt before updating RELEASE_NOTES.md
.\Update-BreakingChanges.ps1 -ConfirmReleaseNotes

# Only detect, do not update RELEASE_NOTES.md
.\Update-BreakingChanges.ps1 -SkipReleaseNotes

# Use a pre-generated swagger.json (skip Swashbuckle CLI step)
.\Update-BreakingChanges.ps1 -SwaggerJsonPath "docs\swagger.json"

# Combine options
.\Update-BreakingChanges.ps1 -BaselineRef "v0.9.5" -ReportPath "breaking.md" -SkipReleaseNotes
```

## What Counts as a Breaking Change

### REST API (swagger.json)

| Change | Breaking |
|--------|---------|
| Endpoint removed | ✓ |
| HTTP method removed from endpoint | ✓ |
| Required parameter added | ✓ |
| Parameter removed | ✓ |
| 2xx response code removed | ✓ |
| Schema (model) removed | ✓ |
| Schema property removed | ✓ |
| Schema property type changed | ✓ |
| Property becomes required | ✓ |
| New endpoint added | ✗ (informational only) |

### .NET API Surface

| Change | Breaking |
|--------|---------|
| Public type removed | ✓ |
| Public member removed (method, property, event) | ✓ |
| New type added | ✗ (informational only) |
| New member added | ✗ (informational only) |

## RELEASE_NOTES.md Integration

Detected breaking changes are automatically appended to the correct section of
`RELEASE_NOTES.md`. The script maps each API surface to its source section:

| API Surface | Section in RELEASE_NOTES.md |
|-------------|----------------------------|
| REST API / Backend API | `- [Backend](...)` |
| Scripting API | `- [Client Scripting](...)` |
| Client Services | `- [Client Services](...)` |

Entries are formatted as:

```markdown
  - removed `PayrunRuntimeBase.GetConsolidatedWageTypeResults` **breaking change**
```

Only new entries are added; existing content is never modified or removed.

## Prerequisites

- .NET SDK 8+ (for `MetadataLoadContext` and `git archive` baseline build)
- Swashbuckle CLI: `dotnet tool install -g Swashbuckle.AspNetCore.Cli`  
  (installed automatically if missing)
- `git` available in `PATH`

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No breaking changes detected |
| `1` | One or more breaking changes found |
| `2` | Infrastructure failure — build, git, or tool error; detection result is unreliable |
