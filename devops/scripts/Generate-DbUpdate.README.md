# Generate-DbUpdate

Generates a database update (delta) script by orchestrating the full
Format → Format → Compare pipeline in a single command.

## Overview

`Generate-DbUpdate.ps1` combines three existing scripts into one step:

```
BaselineFile ──► Format-DbScript ──► Baseline.Formatted.sql ──┐
                                                                ├──► Compare-DbScript ──► TargetFile
CurrentFile  ──► Format-DbScript ──► Current.Formatted.sql  ──┘
```

Both input files are formatted before comparison so that whitespace, comment
and object-order differences do not produce false positives in the diff.

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-BaselineFile` | Yes | — | SQL script representing the OLD schema state |
| `-CurrentFile` | Yes | — | SQL script representing the NEW schema state |
| `-TargetFile` | No | `ModelUpdate.sql` | Output path for the generated delta script |
| `-ScriptsDir` | No | Script directory | Directory containing `Format-DbScript.ps1` and `Compare-DbScript.ps1` |
| `-WorkDir` | No | `$env:TEMP\GenerateDbUpdate_<timestamp>` | Directory for intermediate formatted files |
| `-KeepTemp` | No | `false` | Keep intermediate formatted files after completion |

## What Is Generated

The output delta script contains:

| Change | Output |
|--------|--------|
| Object added | `CREATE` statement |
| Object removed | `DROP` statement (safe, checks existence first) |
| SP / function / view modified | `DROP` + `CREATE` |
| Table modified | `-- TODO` comment — manual `ALTER TABLE` required |

The script header shows a summary:
```sql
-- Changes  : +3 added / -1 removed / ~2 modified
```

## Usage Examples

```powershell
# Minimal – TargetFile defaults to .\ModelUpdate.sql
.\Generate-DbUpdate.ps1 `
    -BaselineFile .\Snapshot_v095.sql `
    -CurrentFile  .\ModelCreate.sql

# Explicit output path
.\Generate-DbUpdate.ps1 `
    -BaselineFile OldSchema\ModelCreate.sql `
    -CurrentFile  NewSchema\ModelCreate.sql `
    -TargetFile   Releases\v0.9.6\ModelUpdate.sql

# Keep intermediate formatted files for inspection
.\Generate-DbUpdate.ps1 `
    -BaselineFile ModelCreate.v095.sql `
    -CurrentFile  ModelCreate.sql `
    -TargetFile   ModelUpdate.sql `
    -KeepTemp

# Custom scripts directory
.\Generate-DbUpdate.ps1 `
    -BaselineFile Snapshot.sql `
    -CurrentFile  ModelCreate.sql `
    -ScriptsDir   C:\Tools\PayrollEngine\Scripts
```

## Typical Release Workflow

```powershell
# Option A — compare against a live DB export
$env:PayrollDatabaseConnection = 'Server=.;Database=PayrollEngine;Integrated Security=True;'
.\Export-DbScript.ps1 -Mode Create -TargetFile Snapshot.sql
.\Generate-DbUpdate.ps1 `
    -BaselineFile Snapshot.sql `
    -CurrentFile  ModelCreate.sql `
    -TargetFile   ModelUpdate.sql

# Option B — compare two file versions directly
.\Generate-DbUpdate.ps1 `
    -BaselineFile Database\ModelCreate.v095.sql `
    -CurrentFile  Database\ModelCreate.sql `
    -TargetFile   Database\ModelUpdate.sql

# After generating the update script, compose version blocks
.\Compose-DbScript.ps1 -ConfigFile DbCompose.json `
    -CreateScriptSource ModelCreate.sql -CreateScriptTarget ModelCreate.Composed.sql `
    -UpdateScriptSource ModelUpdate.sql -UpdateScriptTarget ModelUpdate.Composed.sql
```

## Prerequisites

- `Format-DbScript.ps1` in the same directory (or specify `-ScriptsDir`)
- `Compare-DbScript.ps1` in the same directory (or specify `-ScriptsDir`)
- PowerShell 5.1+

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (delta script written, or no differences found) |
| `1` | Input validation error (file not found, script missing) |
| `≠0` | Error from `Format-DbScript` or `Compare-DbScript` |
