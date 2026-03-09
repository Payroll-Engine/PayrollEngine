# Format-DbScript

Formats a SQL script file: normalises whitespace and GO delimiters, and reorders
DDL objects via topological sort to eliminate forward-reference dependency warnings.

## Overview

`Format-DbScript.ps1` reads a `.sql` file, groups all GO-delimited blocks into
named DDL objects, detects inter-object dependencies, sorts the objects so every
dependency is defined before its dependents, and writes the result to a new file.
The source file is never modified.

The primary use case is pre-processing a script before passing it to
`Compare-DbScript.ps1` or `Generate-DbUpdate.ps1`, so that cosmetic differences
(comment timestamps, GO spacing, SSMS repetition of `USE [db]`) do not produce
false positives in the diff.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-SourceFile` | Yes | Path to the input `.sql` file. Never modified. |
| `-TargetFile` | Yes | Path where the formatted output is written. Created or overwritten. |

## Usage Examples

```powershell
# Basic usage
.\Format-DbScript.ps1 -SourceFile ModelCreate.sql -TargetFile ModelCreate.Formatted.sql

# With explicit paths
.\Format-DbScript.ps1 `
    -SourceFile  C:\...\Backend\Database\ModelCreate.sql `
    -TargetFile  C:\...\Backend\Database\ModelCreate.Formatted.sql
```

## What It Does

### Normalisations Applied

| Normalisation | Detail |
|---------------|--------|
| `USE [<db>]` deduplication | Emitted exactly once after preamble; removed from individual object blocks (SSMS repeats it per object) |
| GO delimiter normalisation | Exactly one blank line before and after each `GO` |
| Trailing whitespace | Stripped from every line |
| Line endings | CRLF (Windows-style, compatible with SSMS and SQL Server tools) |
| SET option blocks | `SET ANSI_NULLS`, `SET QUOTED_IDENTIFIER`, etc. attached to their parent object, not emitted as standalone blocks |

### Dependency Resolution

The script detects references between DDL objects by scanning for:
- `EXEC` / `EXECUTE` calls (stored procedure dependencies)
- UDF calls of the form `[dbo].[FunctionName](` 
- `FROM` / `JOIN` clauses referencing other objects

All objects are then sorted using **Kahn's topological sort** so each object
is defined before the objects that depend on it.

This eliminates SQL Server warnings such as:
> *"The module 'DeleteAllCaseValues' depends on the missing object
> 'dbo.DeleteAllGlobalCaseValues'. The module will still be created; however,
> it cannot run successfully until the object exists."*

If a circular dependency is detected (rare), the affected object is appended
at the end with a `WARNING` message in the console output.

### Object Types Handled

Tables, Views, Functions (scalar, inline, table-valued), Stored Procedures,
Indexes (clustered, nonclustered, unique). Both SSMS-exported scripts (with
`/****** Object: ... ******/` headers) and plain `CREATE ...` scripts are supported.

## Output Structure

```sql
-- Preamble (USE [master], DB creation, collation, RCSI)
GO

USE [PayrollEngine];   -- emitted exactly once
GO

-- DDL objects in dependency order
/****** Object:  Table [dbo].[Tenant] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tenant] ( ... );
GO

/****** Object:  Table [dbo].[Employee] ******/
...
```

## Notes

- Full SQL pretty-printing (clause indentation, keyword casing) is intentionally
  out of scope. Use a dedicated SQL formatter (e.g. `sqlformat`, `Poor Man's
  T-SQL Formatter`) for that purpose.
- `Format-DbScript.ps1` is automatically called by `Generate-DbUpdate.ps1` —
  there is no need to run it manually before generating an update script.
