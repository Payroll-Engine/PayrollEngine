# CumulativeJournal Report

Annual pivot journal showing wage type and collector results for each employee —
one column per month (`M1`–`M12`), one row per wage type or collector, plus a
computed `Total` column.

Demonstrates the canonical pattern for **multi-period aggregation** in a
`ReportEndFunction`: query each month separately, rename the `Value` column to
`M{month}`, merge rows by primary key, then add a computed `Total` expression.

---

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `CumulativeJournal` |
| Script | `Script.cs` (`ReportEndFunction`) |
| Template | `Report.frx` (FastReport) |
| Cultures | `de`, `en` |
| Clusters | `Year` · `Employee` · `Pay` |
| Parameters | `JournalYear`, `Employees.Filter`, `TenantId` |

---

## Script Logic

The `ReportEndFunction` in `Script.cs` assembles the pivot table in three stages.

### Stage 1 — Per-employee, per-month queries

For each employee and each month `m = 1..12`:

1. Call `GetConsolidatedWageTypeResults` with `PeriodStarts=[periodStart]`.
2. Rename the returned `Value` column to `M{m}`.
3. Set `WageTypeNumber` as the primary key and `Merge` into `EmployeeWageTypeResults`.
4. Repeat with `GetConsolidatedCollectorResults`, merging by `CollectorName`.

If a month returns no rows, a typed `M{m}` column (`decimal`) is added to keep
the schema consistent across all 12 months.

### Stage 2 — Computed columns and presence flags

After the 12-month loop:

- `Total` — expression column: `IIF(M1 IS NULL, 0, M1) + ... + IIF(M12 IS NULL, 0, M12)`
- `DeleteRows("Total = 0")` — removes rows with no activity in any month
- `HasM1`–`HasM12` — per-employee presence flags (`0`/`1`): `1` when the employee
  has at least one non-zero value in that month. Used by the template to keep
  explicit zeros visible for months where the employee has other values.
- `IsSummary` — `1` for wage types 200 (GrossWage) and 300 (Auszahlung); used in
  the template to apply bold / separator styling to summary rows.

### Stage 3 — Merge and relations

Employee results are sorted (`EmployeeId ASC, WageTypeNumber ASC`), merged into
the overall `WageTypeResults` / `CollectorResults` tables, and related to the
`Employees` table via:

```
AddRelation("EmployeeWageTypeResults", "Employees", "WageTypeResults",  "EmployeeId")
AddRelation("EmployeeCollectorResults", "Employees", "CollectorResults", "EmployeeId")
```

Temporary per-employee working tables are removed with `RemoveTables(...)` after
each employee to keep the DataSet clean.

---

## Parameters

| Name | Type | Visible | Description |
|:--|:--|:--|:--|
| `TenantId` | Integer | Hidden | Injected by runtime |
| `JournalYear` | Year | Yes | Year to report (default `2025`, min `2000`) |
| `Employees.Filter` | String | Yes | Optional OData name filter for the `QueryEmployees` query |

---

## Data Model

```
Employees (QueryEmployees)
    ├── WageTypeResults  (GetConsolidatedWageTypeResults × 12 months)
    │       EmployeeId → Employees.Id   [EmployeeWageTypeResults]
    └── CollectorResults (GetConsolidatedCollectorResults × 12 months)
            EmployeeId → Employees.Id   [EmployeeCollectorResults]
```

The `Employees` table is populated by the default `QueryEmployees` query declared
in `Report.json`. Both result tables are assembled entirely in the End script.

---

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — parameters, queries, templates |
| `Script.cs` | `ReportEndFunction` — pivot assembly, presence flags, relations |
| `Report.frx` | FastReport template (Landscape, Clean Lines) |
| `parameters.json` | Default parameters for PayrollConsole execution (`JournalYear: 2025`) |
| `Import.pecmd` | Import report definition |
| `Script.pecmd` | Publish `Script.cs` to the regulation |
| `Report.Excel.pecmd` | Run report and save as Excel |
| `Report.Pdf.pecmd` | Run report and save as PDF |
| `Report.Build.pecmd` | Build report schema document for template design |

---

## See Also

- [FastReport Template Development](../FastReport.md) — `ReportBuild` command, initial skeleton, CI schema update
- [Payslip](../Payslip/) — per-period payslip with YTD and retro columns (same aggregation pattern)
- [Best Practices: Reporting](https://payrollengine.org/Concepts/BestPracticesReporting/) — scripting patterns

---

## Features Demonstrated

- **Multi-period pivot in `ReportEndFunction`** — `GetConsolidatedWageTypeResults` and `GetConsolidatedCollectorResults` called once per month; `Value` column renamed to `M1`–`M12`; rows merged by `WageTypeNumber` / `CollectorName`
- **Schema consistency for empty months** — typed `M{m}` column added when a month returns no rows, ensuring all 12 columns exist regardless of data gaps
- **`Total` computed column** — `IIF(Mn IS NULL, 0, Mn)` expression sums all monthly slices; `DeleteRows("Total = 0")` removes inactive rows
- **`HasM1`–`HasM12` presence flags** — per-employee, per-month flags allow the template to show explicit zeros in months that have other values for the same employee
- **`IsSummary` marker** — distinguishes summary rows (WT 200, WT 300) for bold / separator styling in the template without hardcoding formatting in the script
- **Temporary table cleanup** — `RemoveTables(...)` removes per-employee working tables after each employee to keep the DataSet tidy
- **Two static DataRelations** — `EmployeeWageTypeResults` and `EmployeeCollectorResults` registered with `AddRelation`; FastReport renders nested DataBands for each
