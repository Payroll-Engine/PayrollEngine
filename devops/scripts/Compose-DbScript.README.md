# Compose-DbScript

Orchestrates the full DB script composition workflow in one step:

1. Diffs `History\v<OldVersion>\Create-Model.sql` against `Create-Model.sql`
   via `Generate-DbUpdate.ps1` (Format + Compare internally)
2. Replaces `#region VERSION_SET` in `Create-Model.sql` with the `NewVersion` insert
3. Replaces all three regions in `Update-Model.sql` in-place:
   - `#region VERSION_CHECK` ← `OldVersion` check
   - `#region DB_SCRIPTS` ← generated delta SQL
   - `#region VERSION_SET` ← `NewVersion` insert

All modifications are made **in-place**. No separate output files are produced.

## Region Syntax

SQL files use C# region style markers:

```sql
-- #region REGION_NAME
...content...
-- #endregion REGION_NAME
```

Recognised regions in `Create-Model.sql`:

| Region | Managed by |
|--------|------------|
| `DATABASE` | Manual (not touched by this script) |
| `DB_SCRIPTS` | Manual (authoritative schema source) |
| `VERSION_SET` | `Compose-DbScript.ps1` |

Recognised regions in `Update-Model.sql`:

| Region | Managed by |
|--------|------------|
| `VERSION_CHECK` | `Compose-DbScript.ps1` |
| `DB_SCRIPTS` | `Compose-DbScript.ps1` |
| `VERSION_SET` | `Compose-DbScript.ps1` |

## Config File

**`DbVersion.json`** — placed in the `Database\` folder, committed and historized with the SQL scripts:

```json
{
  "OldVersion":          "0.9.5",
  "NewVersion":          "0.9.6",
  "CreateDescription":   "Payroll Engine: Full setup v0.9.6",
  "UpdateDescription":   "Payroll Engine: Migration v0.9.5 -> v0.9.6"
}
```

| Field | Purpose |
|-------|---------|
| `OldVersion` | Expected version in the target DB — used for `VERSION_CHECK` in `Update-Model.sql` and to locate `History\v<OldVersion>\` |
| `NewVersion` | Version written after a successful migration — used in both `VERSION_SET` blocks |
| `CreateDescription` | Free-text description for the version row in the Create script |
| `UpdateDescription` | Free-text description for the version row in the Update script |

## Directory Layout

```
PayrollEngine.Backend\Database\
  DbVersion.json               ← current release config
  Create-Model.sql             ← modified in-place by this script
  Update-Model.sql             ← modified in-place by this script
  Drop-Model.sql               ← not touched by this script
  History\
    v0.9.5\
      Create-Model.sql         ← diff baseline (read-only)
      Update-Model.sql
      Drop-Model.sql
      DbVersion.json
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `-ConfigFile` | No | `DbVersion.json` | Path to the JSON config file |
| `-DatabaseDir` | No | Caller's working directory | Directory containing the SQL files and `History\` |
| `-ScriptsDir` | No | Script's own directory | Directory containing `Generate-DbUpdate.ps1` |
| `-KeepTemp` | No | `false` | Keep the intermediate delta SQL file after completion |
| `-DryRun` | No | `false` | Parse and validate all inputs, print plan, write nothing |

## What Is Injected

### `Create-Model.sql` — `#region VERSION_SET`

```sql
-- #region VERSION_SET
DECLARE @errorID int
INSERT INTO dbo.[Version] (
    MajorVersion,
    MinorVersion,
    SubVersion,
    [Owner],
    [Description] )
VALUES (
    0,
    9,
    6,
    CURRENT_USER,
    'Payroll Engine: Full setup v0.9.6' )
SET @errorID = @@ERROR
IF ( @errorID <> 0 ) BEGIN
    PRINT 'Error while updating the Payroll Engine database version.'
END
ELSE BEGIN
    PRINT 'Payroll Engine database version successfully updated to release 0.9.6'
END
GO
-- #endregion VERSION_SET
```

### `Update-Model.sql` — `#region VERSION_CHECK`

The region starts with `USE [PayrollEngine]` so the script can be run from any
database context (including `master`). `SET XACT_ABORT ON` ensures that any
unexpected error during migration automatically rolls back the open transaction.
If the version check fails, `SET NOEXEC ON` suppresses all subsequent batches
(including `BEGIN TRANSACTION` and `COMMIT`) so no changes are applied.

```sql
-- #region VERSION_CHECK
USE [PayrollEngine];
GO

SET XACT_ABORT ON
GO

DECLARE @MajorVersion int, @MinorVersion int, @SubVersion int
SELECT TOP 1
    @MajorVersion = MajorVersion,
    @MinorVersion = MinorVersion,
    @SubVersion   = SubVersion
FROM dbo.[Version]
ORDER BY MajorVersion DESC, MinorVersion DESC, SubVersion DESC

IF @MajorVersion <> 0 OR @MinorVersion <> 9 OR @SubVersion <> 5 BEGIN
    DECLARE @ActualVersion NVARCHAR(20) =
        CAST(ISNULL(@MajorVersion, -1) AS NVARCHAR) + '.' +
        CAST(ISNULL(@MinorVersion, -1) AS NVARCHAR) + '.' +
        CAST(ISNULL(@SubVersion,   -1) AS NVARCHAR)
    RAISERROR('Version mismatch: expected 0.9.5, found %s', 16, 1, @ActualVersion)
    SET NOEXEC ON   -- suppress all subsequent batches incl. BEGIN TRANSACTION
END
GO
-- #endregion VERSION_CHECK
```

### `Update-Model.sql` — `#region DB_SCRIPTS`

The region opens a transaction and switches to the `PayrollEngine` context, then
contains the delta SQL generated by `Generate-DbUpdate.ps1`:

```sql
BEGIN TRANSACTION
GO

USE [PayrollEngine];
GO
-- ... delta DDL ...
```

Delta content:
- `DROP` + `CREATE` for modified stored procedures and functions
- `CREATE` for new objects
- `DROP` for removed objects
- `-- TODO` comments for modified tables (manual `ALTER TABLE` required)

> **Note:** SQL Server DDL is transactional — `CREATE`/`DROP`/`ALTER` are all
> rolled back automatically if `XACT_ABORT ON` fires on any error.

### `Update-Model.sql` — `#region VERSION_SET`

Commits the transaction and re-enables execution (no-op if `SET NOEXEC` was never
activated):

```sql
-- #region VERSION_SET
DECLARE @errorID int
INSERT INTO dbo.[Version] ...
GO

COMMIT TRANSACTION
GO

SET NOEXEC OFF   -- re-enable execution (in case VERSION_CHECK set it ON)
GO
-- #endregion VERSION_SET
```

### Version Table

Both `VERSION_SET` blocks target `dbo.[Version]`:

| Column | Type | Value |
|--------|------|-------|
| `MajorVersion` | `int` | Parsed from `NewVersion` |
| `MinorVersion` | `int` | Parsed from `NewVersion` |
| `SubVersion` | `int` | Parsed from `NewVersion` |
| `Owner` | `nvarchar` | `CURRENT_USER` (SQL Server built-in) |
| `Description` | `nvarchar` | From `CreateDescription` / `UpdateDescription` |

## Usage Examples

```powershell
# Run from the Database directory (all defaults)
cd Backend\Database
..\..\devops\scripts\Compose-DbScript.ps1

# Explicit config
Compose-DbScript.ps1 -ConfigFile DbVersion.json

# Preview without writing anything
Compose-DbScript.ps1 -DryRun

# Keep the intermediate delta file for inspection
Compose-DbScript.ps1 -KeepTemp

# Explicit paths
Compose-DbScript.ps1 `
    -ConfigFile  C:\...\Database\DbVersion.json `
    -DatabaseDir C:\...\Database `
    -ScriptsDir  C:\...\devops\scripts
```

## Typical Release Workflow

```powershell
cd Backend\Database

# 1. Compose: diff history + update all regions in-place
..\..\devops\scripts\Compose-DbScript.ps1

# 2. Review Update-Model.sql
#    Replace any '-- TODO' table comments with correct ALTER TABLE statements
#    Re-run if corrections affect the diff output

# 3. After release: snapshot into History and advance DbVersion.json
mkdir History\v0.9.6
copy Create-Model.sql  History\v0.9.6\Create-Model.sql
copy Update-Model.sql  History\v0.9.6\Update-Model.sql
copy Drop-Model.sql    History\v0.9.6\Drop-Model.sql
copy DbVersion.json    History\v0.9.6\DbVersion.json

# 4. Advance DbVersion.json for the next release cycle
#    OldVersion = "0.9.6", NewVersion = "0.9.7"
```

## Dependencies

`Compose-DbScript.ps1` calls `Generate-DbUpdate.ps1` internally, which in turn calls
`Format-DbScript.ps1` and `Compare-DbScript.ps1`. All four scripts must be in the
same directory (or override with `-ScriptsDir`).

## Temp Files

The intermediate delta SQL file is written to `$env:TEMP` as
`ComposeDbScript_Delta_<yyyyMMdd_HHmmss>.sql` and deleted automatically after
composition. Use `-KeepTemp` to retain it for inspection.

Formatted and temp files are not committed — add to `.gitignore`:

```
*.Formatted.sql
*_Delta_*.sql
```
