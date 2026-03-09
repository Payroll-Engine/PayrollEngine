# Export-DbScript

Exports the live PayrollEngine database schema to a `.sql` file via SQL Server introspection.

## Overview

`Export-DbScript.ps1` connects to SQL Server using the `PayrollDatabaseConnection`
environment variable and queries the information schema and system catalog to reconstruct
DDL statements for all schema objects. The output is a single `.sql` file that can serve
as a snapshot, a baseline for diffs, or a restore script.

The exported script is unordered (tables may precede or follow their foreign-key targets).
Pipe it through `Format-DbScript.ps1` to resolve dependency order before committing or
using it as a diff baseline.

## Connection String

The connection string is read from the `PayrollDatabaseConnection` environment variable.

Supported formats:

```powershell
# Windows Authentication
$env:PayrollDatabaseConnection = 'Server=.;Database=PayrollEngine;Integrated Security=True;'
$env:PayrollDatabaseConnection = 'Server=.\SQLEXPRESS;Database=PayrollEngine;Integrated Security=True;'

# SQL Authentication
$env:PayrollDatabaseConnection = 'Data Source=localhost;Initial Catalog=PayrollEngine;User Id=sa;Password=***;'
```

## Modes

| Mode | Output |
|------|--------|
| `Create` | `CREATE TABLE`, primary keys, foreign keys, indexes, functions, stored procedures, views |
| `Delete` | Safe `DROP` statements in dependency order (procedures and functions first, then tables) |

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Mode` | Yes | `Create` or `Delete` |
| `-TargetFile` | Yes | Output path for the generated `.sql` file |

## Usage Examples

```powershell
# Set connection string
$env:PayrollDatabaseConnection = 'Server=.;Database=PayrollEngine;Integrated Security=True;'

# Export full CREATE script
.\Export-DbScript.ps1 -Mode Create -TargetFile Snapshot_Create.sql

# Export DROP script
.\Export-DbScript.ps1 -Mode Delete -TargetFile Snapshot_Delete.sql

# Export directly to backend database folder
.\Export-DbScript.ps1 -Mode Create `
    -TargetFile C:\Shared\PayrollEngine\Repos\PayrollEngine.Backend\Database\ModelCreate.sql
```

## What Is Exported

### Create Mode

| Object Type | Details |
|-------------|---------|
| Tables | All base tables with columns, data types, identity, nullability, defaults |
| Primary Keys | Inline as `CONSTRAINT ... PRIMARY KEY` within `CREATE TABLE` |
| Foreign Keys | Inline as `CONSTRAINT ... FOREIGN KEY` within `CREATE TABLE` |
| Indexes | All non-primary-key indexes (unique, clustered, nonclustered) with INCLUDE columns |
| Views | Full `CREATE VIEW` definition from `sys.sql_modules` |
| Functions | Scalar, inline table-valued, and table-valued UDFs |
| Stored Procedures | Full `CREATE PROCEDURE` definition |

### Delete Mode

Objects are dropped in safe dependency order:
1. Stored procedures
2. Functions (scalar, then table-valued)
3. Views
4. Tables

All `DROP` statements are guarded with `IF OBJECT_ID(...) IS NOT NULL`.

## Output Format

The Create script uses SSMS-compatible headers for each object:

```sql
/****** Object:  Table [dbo].[Employee] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee] (
    [Id]         INT           NOT NULL IDENTITY(1, 1),
    [Identifier] NVARCHAR(128) NOT NULL,
    ...
    CONSTRAINT [PK_Employee] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Employee_Tenant] FOREIGN KEY ([TenantId]) REFERENCES [dbo].[Tenant] ([Id])
);
GO
```

## Prerequisites

- .NET 8+ (provides `Microsoft.Data.SqlClient`) or .NET Framework (uses `System.Data.SqlClient`)
- `PayrollDatabaseConnection` environment variable set
- Read access to the target database

## Typical Workflow

```powershell
# 1. Export current DB state
.\Export-DbScript.ps1 -Mode Create -TargetFile Snapshot.sql

# 2. Generate update script against updated ModelCreate.sql
.\Generate-DbUpdate.ps1 `
    -BaselineFile Snapshot.sql `
    -CurrentFile  ModelCreate.sql `
    -TargetFile   ModelUpdate.sql

# 3. Compose version blocks
.\Compose-DbScript.ps1 -ConfigFile DbCompose.json `
    -CreateScriptSource ModelCreate.sql -CreateScriptTarget ModelCreate.Composed.sql `
    -UpdateScriptSource ModelUpdate.sql -UpdateScriptTarget ModelUpdate.Composed.sql
```
