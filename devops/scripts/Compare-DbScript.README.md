# Compare-DbScript

Compares two formatted SQL script files and generates a delta script that migrates
a database from the baseline state to the current state.

## Overview

`Compare-DbScript.ps1` parses both input files into named DDL objects, computes
the difference, and emits a ready-to-apply update script. Both files should be
pre-processed by `Format-DbScript.ps1` to avoid false positives from whitespace
or comment differences.

For a single-command pipeline that handles formatting automatically, use
`Generate-DbUpdate.ps1` instead.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-BaselineFile` | Yes | Formatted SQL file representing the OLD / source schema state |
| `-CurrentFile` | Yes | Formatted SQL file representing the NEW / target schema state |
| `-TargetFile` | Yes | Path where the delta `.sql` script is written. Created or overwritten. |

## Usage Examples

```powershell
# Compare two pre-formatted files
.\Compare-DbScript.ps1 `
    -BaselineFile ModelCreate.Formatted.sql `
    -CurrentFile  ModelCreate.New.Formatted.sql `
    -TargetFile   ModelUpdate.sql

# Compare a dated snapshot against the current model
.\Compare-DbScript.ps1 `
    -BaselineFile Snapshot_Create.sql `
    -CurrentFile  ModelCreate.sql `
    -TargetFile   ModelUpdate_$(Get-Date -Format 'yyyyMMdd').sql
```

## Diff Categories

| Category | Condition | Output |
|----------|-----------|--------|
| **Added** | Object in Current but not in Baseline | `CREATE` statement |
| **Removed** | Object in Baseline but not in Current | `DROP` statement (existence-guarded) |
| **Modified** | Object in both with different body | `DROP` + `CREATE` (programmable); `-- TODO` (tables) |
| **Equal** | Object in both with identical body | Not included in delta script |

Equality is determined on normalised bodies: comments containing date stamps and
all extra whitespace are stripped before comparison to avoid spurious diffs.

## Table Changes

Modified **tables** are not automatically altered. The script emits a `-- TODO`
comment to flag them for manual review:

```sql
-- TODO: Table [dbo].[Employee] was modified.
-- Review column differences and write ALTER TABLE statements manually.
GO
```

All other modified object types (stored procedures, functions, views, indexes)
are handled automatically via `DROP` + `CREATE`.

## Delta Script Structure

```sql
-- ============================================================
-- Delta Update Script
-- Baseline : ModelCreate.Formatted.sql
-- Current  : ModelCreate.New.Formatted.sql
-- Generated: 2025-04-01 14:22
-- Changes  : +3 added / -1 removed / ~2 modified
-- ============================================================
GO

-- ------------------------------------------------------------
-- Removed objects (1)
-- ------------------------------------------------------------
IF OBJECT_ID('[dbo].[OldProcedure]') IS NOT NULL
    DROP PROCEDURE [dbo].[OldProcedure];
GO

-- ------------------------------------------------------------
-- Modified objects -- drop before re-create (2)
-- ------------------------------------------------------------
IF OBJECT_ID('[dbo].[GetEmployees]') IS NOT NULL
    DROP PROCEDURE [dbo].[GetEmployees];
GO

-- ------------------------------------------------------------
-- Added objects (3)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[NewProcedure] ...
GO

-- ------------------------------------------------------------
-- Modified objects -- re-create (2)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[GetEmployees] ...
GO
```

## DROP Statement Safety

All `DROP` statements are guarded to be idempotent:

```sql
-- Tables
IF OBJECT_ID('[dbo].[TableName]', 'U') IS NOT NULL
    DROP TABLE [dbo].[TableName];

-- Programmable objects
IF OBJECT_ID('[dbo].[ProcName]') IS NOT NULL
    DROP PROCEDURE [dbo].[ProcName];
```

For indexes, a manual `DROP` comment is emitted (the table name is not available
in the object context).

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (delta script written, or schemas are identical — no file generated) |
| `1` | Input validation error |
