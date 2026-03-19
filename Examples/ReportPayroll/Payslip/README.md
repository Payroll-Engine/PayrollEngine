# Payslip Report

A payslip report for a single pay period, showing current values, year-to-date
totals, and retro corrections for each employee. Demonstrates the two central
reporting concepts in PayrollEngine: **Period Totals (YTD)** and **Retro Values**.

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `Payslip` |
| Script | `Script.cs` |
| Template | `Report.frx` (FastReport) |
| Cultures | `de`, `en` |
| Parameters | `PayslipYear`, `PayslipMonth`, `EmployeeIdentifier` |

## Columns

| Column | Description |
|:--|:--|
| **Current** | Value calculated by the payrun for the payslip month |
| **Retro** | Accumulated correction from retroactive recalculations of prior months |
| **YTD** | Sum of all periods from January through the payslip month |

## How YTD is calculated

YTD is computed in `ReportEndFunction` — **not** in the payrun. For each prior
month `m = 1..month-1`, `GetConsolidatedWageTypeResults` is called once with
`PeriodStarts=[m]`. The returned `Value` column is renamed to `M{m}`. After the
loop the `YtdValue` computed column sums all monthly slices:

```
YtdValue = M1 + M2 + ... + M(month-1) + CurrentValue
```

Calling these queries during payrun execution would be prohibitively expensive
and conceptually wrong — a payrun result must depend only on the current period's
inputs. See [Period Totals](https://payrollengine.org/Concepts/PeriodTotals/) for
the design rationale.

## How RetroValue is calculated

For each prior month `m`, a second call is made with an additional `EvaluationDate`
set to the start of month `m+1`. This returns the value as it was stored by the
original payrun — before any later corrections were applied:

```
RetroValue = Σ (consolidated(m) − original(m))   for m = 1..month-1
```

A non-zero `RetroValue` means that subsequent case changes caused the engine to
re-execute historical payrun periods and the employee's net pay must be corrected
in the current payslip. See [Retro Corrections](https://payrollengine.org/Concepts/RetroCorrections/)
for the full model.

## Test data

The example includes a deliberate retro scenario for **Alice Miller**:

- Months Jan–Feb 2025: `MonthlyWage = 7,000`, employment level 80 % → original gross = 5,600
- Case change created **2025-03-15**: `MonthlyWage` retroactively set to 6,000 for Jan–Feb
- March payrun detects the `ValueChange` mutation and auto-creates retro jobs for Jan and Feb
- March payslip shows `RetroValue = −1,600` for WT 101 (= 2 × (4,800 − 5,600))

## Running the report

```
# rebuild script after code changes
ScriptPublish Script.cs /wait

# generate PDF (opens automatically)
Report tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:Payslip culture:de-CH /pdf /shellopen
```

Or use the provided `.pecmd` files:

| File | Action |
|:--|:--|
| `Script.pecmd` | Publish `Script.cs` |
| `Report.Pdf.pecmd` | Generate and open PDF |
| `Report.Excel.pecmd` | Generate Excel output |
| `Report.Build.pecmd` | Build report schema document |

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — parameters, queries, template references |
| `Script.cs` | `ReportEndFunction` — YTD and retro aggregation logic |
| `Report.frx` | FastReport template — "Clean Lines" layout |
| `parameters.json` | Default parameters for console execution |

## See Also

- [FastReport Template Development](../FastReport.md) — `ReportBuild` command, initial skeleton, CI schema update
- [Period Totals](https://payrollengine.org/Concepts/PeriodTotals/) — design rationale for report-time YTD
- [Retro Corrections](https://payrollengine.org/Concepts/RetroCorrections/) — how retroactive recalculations work
- [Best Practices: Reporting](https://payrollengine.org/Concepts/BestPracticesReporting/) — scripting patterns
- [CumulativeJournal](../CumulativeJournal/) — multi-period journal example (YTD without retro)

---

## Features Demonstrated

- **Report-time YTD aggregation** — `GetConsolidatedWageTypeResults` called once per prior month; `Value` column renamed to `M1`–`M12`; `YtdValue` computed column sums all slices
- **Retro value calculation** — each prior month queried twice (consolidated vs. original stored); the difference accumulates as `RetroValue`
- **`ReportEndFunction` for post-payrun computation** — YTD and retro computed in the report script, not in the payrun; keeps payrun results period-isolated
- **Employee filter via parameter** — `EmployeeIdentifier` restricts output to one employee when provided; empty = all employees
- **`DeleteRows` for zero suppression** — rows where `YtdValue = 0` are removed before rendering
- **Clean Lines FRX layout** — portrait A4, navy header, gold-underline column headers, horizontal separators
