<#
.SYNOPSIS
    Exports the PayrollEngine database schema to a SQL script file.

.DESCRIPTION
    Connects to SQL Server using the connection string stored in the environment
    variable "PayrollDatabaseConnection" and generates a .sql script file.

    Modes:
      Create  --  generates CREATE statements for all schema objects
                  (tables, columns, defaults, check constraints, foreign keys,
                   indexes, functions, stored procedures, views)
      Delete  --  generates DROP statements for all schema objects in the
                  correct order (procedures/functions first, then tables)

    The output script is not guaranteed to be ordered or formatted; pipe it
    through Format-DbScript.ps1 to resolve dependency order and normalise style.
    Use Compare-DbScript.ps1 to compare two snapshots and produce an update script.

.PARAMETER Mode
    Export mode: Create or Delete.

.PARAMETER TargetFile
    Path where the generated .sql script is written.  Created or overwritten.

.NOTES
    Connection string environment variable: PayrollDatabaseConnection
    Supported formats:
      Server=.\SQLEXPRESS;Database=PayrollEngine;Integrated Security=True;
      Data Source=localhost;Initial Catalog=PayrollEngine;User Id=sa;Password=***;

    Required: Microsoft.Data.SqlClient (bundled with .NET 8+) or
              System.Data.SqlClient (.NET Framework).

.EXAMPLE
    .\Export-DbScript.ps1 -Mode Create -TargetFile Snapshot_Create.sql
    .\Export-DbScript.ps1 -Mode Delete -TargetFile Snapshot_Delete.sql
    .\Export-DbScript.ps1 -Mode Create -TargetFile C:\...\Database\ModelCreate.sql
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Create', 'Delete')][string]$Mode,
    [Parameter(Mandatory)][string]$TargetFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Section([string]$title) {
    $line = "-" * 70
    Write-Host "`n$line" -ForegroundColor DarkGray
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "$line" -ForegroundColor DarkGray
}

function Write-Ok([string]$msg)   { Write-Host "  OK:      $msg" -ForegroundColor Green   }
function Write-Info([string]$msg) { Write-Host "  INFO:    $msg" -ForegroundColor DarkGray }
function Write-Warn([string]$msg) { Write-Host "  WARNING: $msg" -ForegroundColor Yellow  }

# ---------------------------------------------------------------------------
# Connection
# ---------------------------------------------------------------------------

function Get-ConnectionString {
    $cs = $env:PayrollDatabaseConnection
    if ([string]::IsNullOrWhiteSpace($cs)) {
        Write-Host "  ERROR: Environment variable 'PayrollDatabaseConnection' is not set." -ForegroundColor Red
        exit 1
    }
    return $cs
}

function Open-SqlConnection([string]$connectionString) {
    try {
        # Prefer Microsoft.Data.SqlClient (modern); fall back to System.Data.SqlClient
        $conn = $null
        try {
            $conn = New-Object Microsoft.Data.SqlClient.SqlConnection($connectionString)
        } catch {
            $conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        }
        $conn.Open()
        return $conn
    } catch {
        Write-Host "  ERROR: Cannot connect to SQL Server: $_" -ForegroundColor Red
        exit 1
    }
}

function Invoke-Query([System.Data.Common.DbConnection]$conn, [string]$sql) {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = $sql
    $cmd.CommandTimeout = 120
    $reader = $cmd.ExecuteReader()
    $rows = [System.Collections.Generic.List[hashtable]]::new()
    while ($reader.Read()) {
        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $row[$reader.GetName($i)] = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
        }
        $rows.Add($row)
    }
    $reader.Close()
    return $rows
}

# ---------------------------------------------------------------------------
# Schema Queries
# ---------------------------------------------------------------------------

$Q_TABLES = @"
SELECT t.TABLE_SCHEMA, t.TABLE_NAME
FROM   INFORMATION_SCHEMA.TABLES t
WHERE  t.TABLE_TYPE = 'BASE TABLE'
ORDER  BY t.TABLE_SCHEMA, t.TABLE_NAME
"@

$Q_COLUMNS = @"
SELECT
    c.TABLE_SCHEMA, c.TABLE_NAME, c.COLUMN_NAME, c.ORDINAL_POSITION,
    c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH, c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE, c.IS_NULLABLE, c.COLUMN_DEFAULT,
    COLUMNPROPERTY(OBJECT_ID(c.TABLE_SCHEMA+'.'+c.TABLE_NAME), c.COLUMN_NAME, 'IsIdentity') AS IS_IDENTITY,
    IDENT_SEED(c.TABLE_SCHEMA+'.'+c.TABLE_NAME)      AS IDENTITY_SEED,
    IDENT_INCR(c.TABLE_SCHEMA+'.'+c.TABLE_NAME)      AS IDENTITY_INCR
FROM   INFORMATION_SCHEMA.COLUMNS c
ORDER  BY c.TABLE_SCHEMA, c.TABLE_NAME, c.ORDINAL_POSITION
"@

$Q_PK = @"
SELECT
    tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME,
    STRING_AGG('[' + kcu.COLUMN_NAME + ']', ', ')
        WITHIN GROUP (ORDER BY kcu.ORDINAL_POSITION) AS COLUMNS
FROM   INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN   INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
       ON  kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
       AND kcu.TABLE_SCHEMA    = tc.TABLE_SCHEMA
WHERE  tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
GROUP  BY tc.TABLE_SCHEMA, tc.TABLE_NAME, tc.CONSTRAINT_NAME
"@

$Q_INDEXES = @"
SELECT
    s.name  AS TABLE_SCHEMA,
    t.name  AS TABLE_NAME,
    i.name  AS INDEX_NAME,
    i.is_unique,
    i.type_desc,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 THEN '[' + c.name + ']' + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END END,
        ', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS KEY_COLUMNS,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 1 THEN '[' + c.name + ']' END,
        ', '
    ) WITHIN GROUP (ORDER BY ic.index_column_id) AS INCLUDE_COLUMNS
FROM   sys.indexes i
JOIN   sys.tables  t  ON t.object_id = i.object_id
JOIN   sys.schemas s  ON s.schema_id = t.schema_id
JOIN   sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN   sys.columns c  ON c.object_id = i.object_id AND c.column_id = ic.column_id
WHERE  i.is_primary_key = 0
  AND  i.type > 0
  AND  t.is_ms_shipped = 0
GROUP  BY s.name, t.name, i.name, i.is_unique, i.type_desc
ORDER  BY s.name, t.name, i.name
"@

$Q_FK = @"
SELECT
    fk.name               AS FK_NAME,
    ps.name               AS PARENT_SCHEMA,
    pt.name               AS PARENT_TABLE,
    rs.name               AS REF_SCHEMA,
    rt.name               AS REF_TABLE,
    STRING_AGG('[' + pc.name + ']', ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS PARENT_COLS,
    STRING_AGG('[' + rc.name + ']', ', ') WITHIN GROUP (ORDER BY fkc.constraint_column_id) AS REF_COLS,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc
FROM   sys.foreign_keys fk
JOIN   sys.tables  pt  ON pt.object_id = fk.parent_object_id
JOIN   sys.schemas ps  ON ps.schema_id = pt.schema_id
JOIN   sys.tables  rt  ON rt.object_id = fk.referenced_object_id
JOIN   sys.schemas rs  ON rs.schema_id = rt.schema_id
JOIN   sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN   sys.columns pc ON pc.object_id = fkc.parent_object_id   AND pc.column_id = fkc.parent_column_id
JOIN   sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
GROUP  BY fk.name, ps.name, pt.name, rs.name, rt.name,
          fk.delete_referential_action_desc, fk.update_referential_action_desc
ORDER  BY ps.name, pt.name, fk.name
"@

$Q_MODULES = @"
SELECT
    s.name        AS SCHEMA_NAME,
    o.name        AS OBJECT_NAME,
    o.type_desc   AS OBJECT_TYPE,
    sm.definition AS DEFINITION
FROM   sys.sql_modules sm
JOIN   sys.objects     o  ON o.object_id = sm.object_id
JOIN   sys.schemas     s  ON s.schema_id = o.schema_id
WHERE  o.type IN ('P','FN','IF','TF','V')   -- SP, scalar/table/inline UDF, View
  AND  o.is_ms_shipped = 0
ORDER  BY
    -- Views before functions before SPs (rough dependency order; DbScriptFormat refines)
    CASE o.type WHEN 'V' THEN 1 WHEN 'FN' THEN 2 WHEN 'IF' THEN 3 WHEN 'TF' THEN 4 ELSE 5 END,
    s.name, o.name
"@

# ---------------------------------------------------------------------------
# DDL Builders
# ---------------------------------------------------------------------------

function Build-ColumnDef([hashtable]$col) {
    $name = "[$($col.COLUMN_NAME)]"

    $typePart = switch ($col.DATA_TYPE) {
        'nvarchar'  { "NVARCHAR($( if ($col.CHARACTER_MAXIMUM_LENGTH -eq -1) { 'MAX' } else { $col.CHARACTER_MAXIMUM_LENGTH } ))" }
        'varchar'   { "VARCHAR($( if ($col.CHARACTER_MAXIMUM_LENGTH -eq -1) { 'MAX' } else { $col.CHARACTER_MAXIMUM_LENGTH } ))" }
        'nchar'     { "NCHAR($($col.CHARACTER_MAXIMUM_LENGTH))" }
        'char'      { "CHAR($($col.CHARACTER_MAXIMUM_LENGTH))" }
        'decimal'   { "DECIMAL($($col.NUMERIC_PRECISION), $($col.NUMERIC_SCALE))" }
        'numeric'   { "NUMERIC($($col.NUMERIC_PRECISION), $($col.NUMERIC_SCALE))" }
        default     { $col.DATA_TYPE.ToUpper() }
    }

    $identity = if ($col.IS_IDENTITY -eq 1) {
        " IDENTITY($($col.IDENTITY_SEED), $($col.IDENTITY_INCR))"
    } else { '' }

    $nullable = if ($col.IS_NULLABLE -eq 'NO') { ' NOT NULL' } else { ' NULL' }

    $default = if ($col.COLUMN_DEFAULT) { " DEFAULT $($col.COLUMN_DEFAULT)" } else { '' }

    return "    $name $typePart$identity$nullable$default"
}

function Build-CreateTable(
    [string]$schema,
    [string]$table,
    [System.Collections.Generic.List[hashtable]]$columns,
    [hashtable]$pk,
    [System.Collections.Generic.List[hashtable]]$fks
) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("/****** Object:  Table [$schema].[$table] ******/")
    [void]$sb.AppendLine("SET ANSI_NULLS ON")
    [void]$sb.AppendLine("GO")
    [void]$sb.AppendLine("SET QUOTED_IDENTIFIER ON")
    [void]$sb.AppendLine("GO")
    [void]$sb.AppendLine("CREATE TABLE [$schema].[$table] (")

    $defs = [System.Collections.Generic.List[string]]::new()
    foreach ($col in $columns) { $defs.Add((Build-ColumnDef $col)) }
    if ($pk) { $defs.Add("    CONSTRAINT [$($pk.CONSTRAINT_NAME)] PRIMARY KEY ($($pk.COLUMNS))") }
    foreach ($fk in $fks) {
        $onDel = if ($fk.delete_referential_action_desc -ne 'NO_ACTION') { " ON DELETE $($fk.delete_referential_action_desc -replace '_',' ')" } else { '' }
        $onUpd = if ($fk.update_referential_action_desc -ne 'NO_ACTION') { " ON UPDATE $($fk.update_referential_action_desc -replace '_',' ')" } else { '' }
        $defs.Add("    CONSTRAINT [$($fk.FK_NAME)] FOREIGN KEY ($($fk.PARENT_COLS)) REFERENCES [$($fk.REF_SCHEMA)].[$($fk.REF_TABLE)] ($($fk.REF_COLS))$onDel$onUpd")
    }

    [void]$sb.AppendLine(($defs -join ",`r`n"))
    [void]$sb.AppendLine(");")
    [void]$sb.AppendLine("GO")
    return $sb.ToString()
}

function Build-CreateIndex([hashtable]$idx) {
    $unique    = if ($idx.is_unique) { 'UNIQUE ' } else { '' }
    $clustered = if ($idx.type_desc -eq 'CLUSTERED') { 'CLUSTERED ' } else { 'NONCLUSTERED ' }
    $include   = if ($idx.INCLUDE_COLUMNS) { "`r`n    INCLUDE ($($idx.INCLUDE_COLUMNS))" } else { '' }
    return @"
/****** Object:  Index [$($idx.TABLE_SCHEMA)].[$($idx.TABLE_NAME)].[$($idx.INDEX_NAME)] ******/
CREATE ${unique}${clustered}INDEX [$($idx.INDEX_NAME)]
    ON [$($idx.TABLE_SCHEMA)].[$($idx.TABLE_NAME)] ($($idx.KEY_COLUMNS))$include;
GO
"@
}

function Build-CreateModule([hashtable]$mod) {
    $def = $mod.DEFINITION.Trim()
    return @"
/****** Object:  $($mod.OBJECT_TYPE) [$($mod.SCHEMA_NAME)].[$($mod.OBJECT_NAME)] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
$def
GO
"@
}

function Build-DropAll(
    [System.Collections.Generic.List[hashtable]]$modules,
    [System.Collections.Generic.List[hashtable]]$tables
) {
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("-- ============================================================")
    [void]$sb.AppendLine("-- DROP all schema objects")
    [void]$sb.AppendLine("-- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    [void]$sb.AppendLine("-- ============================================================")
    [void]$sb.AppendLine("GO")

    # Drop modules in reverse order (SPs first, then UDFs, then Views)
    $dropOrder = $modules | Sort-Object {
        switch ($_.OBJECT_TYPE) {
            'SQL_STORED_PROCEDURE' { 1 }
            'SQL_SCALAR_FUNCTION'  { 2 }
            'SQL_INLINE_TABLE_VALUED_FUNCTION' { 3 }
            'SQL_TABLE_VALUED_FUNCTION' { 4 }
            'VIEW' { 5 }
            default { 9 }
        }
    }

    foreach ($mod in $dropOrder) {
        $typeKeyword = switch ($mod.OBJECT_TYPE) {
            'SQL_STORED_PROCEDURE'              { 'PROCEDURE' }
            'SQL_SCALAR_FUNCTION'               { 'FUNCTION'  }
            'SQL_INLINE_TABLE_VALUED_FUNCTION'  { 'FUNCTION'  }
            'SQL_TABLE_VALUED_FUNCTION'         { 'FUNCTION'  }
            'VIEW'                              { 'VIEW'      }
            default                             { 'OBJECT'    }
        }
        [void]$sb.AppendLine("IF OBJECT_ID('[$($mod.SCHEMA_NAME)].[$($mod.OBJECT_NAME)]') IS NOT NULL")
        [void]$sb.AppendLine("    DROP $typeKeyword [$($mod.SCHEMA_NAME)].[$($mod.OBJECT_NAME)];")
        [void]$sb.AppendLine("GO")
    }

    # Drop tables (FK constraints first via CASCADE-safe approach)
    foreach ($tbl in $tables) {
        [void]$sb.AppendLine("IF OBJECT_ID('[$($tbl.TABLE_SCHEMA)].[$($tbl.TABLE_NAME)]', 'U') IS NOT NULL")
        [void]$sb.AppendLine("    DROP TABLE [$($tbl.TABLE_SCHEMA)].[$($tbl.TABLE_NAME)];")
        [void]$sb.AppendLine("GO")
    }

    return $sb.ToString()
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

$startTime = Get-Date
Write-Host "`n  PayrollEngine Export-DbScript  --  Mode: $Mode" -ForegroundColor White
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray

# Resolve relative paths against the caller's working directory, not System32
$callerDir = (Get-Location).Path
if (-not [System.IO.Path]::IsPathRooted($TargetFile)) {
    $TargetFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($callerDir, $TargetFile))
}

Write-Section "Connection"
$cs   = Get-ConnectionString
$conn = Open-SqlConnection $cs

$db = ''
foreach ($part in $cs -split ';') {
    if ($part -match '(?i)^(?:Database|Initial\s+Catalog)\s*=\s*(.+)$') {
        $db = $Matches[1].Trim(); break
    }
}
Write-Ok "Connected  Database: $db"

# Set database context
$setDb = $conn.CreateCommand()
$setDb.CommandText = if ($db) { "USE [$db];" } else { "SELECT DB_NAME();" }
[void]$setDb.ExecuteNonQuery()

Write-Section "Schema Query"
$tables  = Invoke-Query $conn $Q_TABLES
$columns = Invoke-Query $conn $Q_COLUMNS
$pks     = Invoke-Query $conn $Q_PK
$indexes = Invoke-Query $conn $Q_INDEXES
$fks     = Invoke-Query $conn $Q_FK
$modules = Invoke-Query $conn $Q_MODULES

Write-Info "Tables     : $($tables.Count)"
Write-Info "Columns    : $($columns.Count)"
Write-Info "Indexes    : $($indexes.Count)"
Write-Info "FK         : $($fks.Count)"
Write-Info "Modules    : $($modules.Count)  (SP/UDF/View)"

$conn.Close()

Write-Section "Building Script"

$targetDir = Split-Path $TargetFile -Parent
if ($targetDir -and -not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

if ($Mode -eq 'Delete') {
    $sql = Build-DropAll $modules $tables
    [System.IO.File]::WriteAllText($TargetFile, $sql, [System.Text.Encoding]::UTF8)
    Write-Ok "DELETE script written"
}
else {
    # Group columns, PKs, FKs by table
    $colsByTable = @{}
    foreach ($col in $columns) {
        $key = "$($col.TABLE_SCHEMA).$($col.TABLE_NAME)"
        if (-not $colsByTable.ContainsKey($key)) {
            $colsByTable[$key] = [System.Collections.Generic.List[hashtable]]::new()
        }
        $colsByTable[$key].Add($col)
    }

    $pkByTable = @{}
    foreach ($pk in $pks) { $pkByTable["$($pk.TABLE_SCHEMA).$($pk.TABLE_NAME)"] = $pk }

    $fksByTable = @{}
    foreach ($fk in $fks) {
        $key = "$($fk.PARENT_SCHEMA).$($fk.PARENT_TABLE)"
        if (-not $fksByTable.ContainsKey($key)) {
            $fksByTable[$key] = [System.Collections.Generic.List[hashtable]]::new()
        }
        $fksByTable[$key].Add($fk)
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("-- ============================================================")
    [void]$sb.AppendLine("-- CREATE script snapshot  --  Database: $db")
    [void]$sb.AppendLine("-- Generated : $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    [void]$sb.AppendLine("-- Run DbScriptFormat to resolve dependency order and style.")
    [void]$sb.AppendLine("-- ============================================================")
    [void]$sb.AppendLine("GO")
    [void]$sb.AppendLine("USE [$db];")
    [void]$sb.AppendLine("GO")
    [void]$sb.AppendLine("")

    # Tables
    foreach ($tbl in $tables) {
        $key = "$($tbl.TABLE_SCHEMA).$($tbl.TABLE_NAME)"
        $cols = if ($colsByTable.ContainsKey($key)) { $colsByTable[$key] } else {
            [System.Collections.Generic.List[hashtable]]::new()
        }
        $pk   = if ($pkByTable.ContainsKey($key)) { $pkByTable[$key] } else { $null }
        $tfks = if ($fksByTable.ContainsKey($key)) { $fksByTable[$key] } else {
            [System.Collections.Generic.List[hashtable]]::new()
        }
        [void]$sb.AppendLine((Build-CreateTable $tbl.TABLE_SCHEMA $tbl.TABLE_NAME $cols $pk $tfks))
        Write-Info "  TABLE $key"
    }

    # Indexes
    foreach ($idx in $indexes) {
        [void]$sb.AppendLine((Build-CreateIndex $idx))
    }

    # Modules (Views, Functions, Stored Procedures)
    foreach ($mod in $modules) {
        [void]$sb.AppendLine((Build-CreateModule $mod))
        Write-Info "  $($mod.OBJECT_TYPE.PadRight(35)) $($mod.SCHEMA_NAME).$($mod.OBJECT_NAME)"
    }

    [System.IO.File]::WriteAllText($TargetFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
    Write-Ok "CREATE script written"
}

$outInfo = Get-Item $TargetFile
Write-Ok "Output: $TargetFile  ($([Math]::Round($outInfo.Length / 1KB, 1)) KB)"

$elapsed = (Get-Date) - $startTime
Write-Host "`n$("-" * 70)" -ForegroundColor DarkGray
Write-Host "  DONE  |  $($elapsed.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
exit 0
