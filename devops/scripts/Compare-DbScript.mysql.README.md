# MySQL Database Script Tools

Three PowerShell scripts that mirror the SQL Server diff workflow for MySQL.

## Scripts

| Script | Purpose |
|---|---|
| `Compare-DbScript.mysql.ps1` | Diffs two `Create-Model.mysql.sql` files and generates a delta SQL script |
| `Generate-DbUpdate.mysql.ps1` | Orchestrates the diff (no Format step needed for MySQL) |
| `Compose-DbScript.mysql.ps1` | Full workflow: diff + update `Create-Model.mysql.sql` + regenerate `Update-Model.mysql.sql` |

## Usage

### Full workflow (from the Database directory)

```powershell
cd Backend\Database
..\..\devops\scripts\Compose-DbScript.mysql.ps1
```

Reads `DbVersion.json`, diffs `History\v<OldVersion>\Create-Model.mysql.sql`
against `Create-Model.mysql.sql`, and regenerates `Update-Model.mysql.sql`.

### Dry-run first

```powershell
Compose-DbScript.mysql.ps1 -DryRun
```

### Delta only (without updating files)

```powershell
Generate-DbUpdate.mysql.ps1 `
    -BaselineFile History\v0.9.6\Create-Model.mysql.sql `
    -CurrentFile  Create-Model.mysql.sql `
    -TargetFile   delta.mysql.sql
```

## Before each release

**Copy `Create-Model.mysql.sql` to `History\v<CurrentVersion>\` BEFORE making changes.**

```powershell
# Example: before starting 0.9.7 work
$ver = "0.9.6"
New-Item -ItemType Directory -Path "History\v$ver" -Force
Copy-Item Create-Model.mysql.sql "History\v$ver\Create-Model.mysql.sql"
```

Without this step, the diff baseline for the next release is missing.

## Differences vs SQL Server workflow

| Aspect | SQL Server | MySQL |
|---|---|---|
| Block delimiter | `GO` | `$$` |
| Object headers | SSMS `/* Object: ... */` | `CREATE PROCEDURE/FUNCTION/TABLE` |
| Format step | Required (SSMS header normalisation) | **Not needed** |
| Update-Model generation | Region-patch (`#region`/`#endregion`) | **Full regeneration** |
| Version check | T-SQL `RAISERROR` + `SET NOEXEC ON` | MySQL SP + `SIGNAL SQLSTATE` |
| Schema export from DB | `Export-DbScript.ps1` (SQL Server only) | Not implemented (manual) |
