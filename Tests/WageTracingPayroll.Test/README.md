# Wage Tracing Payroll Test

A focused test demonstrating **wage calculation traceability** via
`clusterSetWageTypePeriod` — the engine's mechanism for storing one
`Wage Type Custom Result` per case value time split within a pay period.

The test is intentionally minimal: one wage type, two employees, two months.
All calculation logic is No-Code.

---

## Background — Wage Calculation Traceability

When `clusterSetWageTypePeriod` is set on a payroll, every wage type in the
referenced cluster set stores one `Wage Type Custom Result` for each case value
combination that was active during the pay period. This turns the aggregated
wage type result into a fully auditable derivation:

- **Source = wertgebendes Case Field** (e.g. `Salary`): prorated partial WT values — sum equals the aggregated result
- **Source = weitere Case Fields** (e.g. `EmploymentLevel`): raw case values as audit reference

> See [Wage Calculation Traceability](https://payrollengine.org/AdvancedTopics/Compliance#wage-calculation-traceability)
> in the Payroll Engine documentation.

---

## Scenario Overview

Two employees in the Operations division. Two monthly payruns (Jan–Feb 2025).

| Run | Evaluation Date | Events |
|---|---|---|
| Jan 2025 | 2025-01-31 | Baseline — no splits, one Custom Result per employee |
| **Feb 2025** | 2025-02-28 | **Alex**: Salary split Feb 10 · **Sam**: EmploymentLevel split Feb 15 |

---

## Employees

| Employee | Salary | EmploymentLevel | Change in February |
|---|---|---|---|
| Alex Brown | 4 000 → **5 600** | 1.0 (stable) | Salary increase effective Feb 10 |
| Sam Green | 3 600 (stable) | 0.8 → **1.0** | Level increase effective Feb 15 |

---

## Regulation: WageTracingRegulation

### Cases

| Case | Type | Field | Value type | Time type |
|---|---|---|---|---|
| `Salary` | Employee | Salary | Money | CalendarPeriod |
| `EmploymentLevel` | Employee | EmploymentLevel | Percent | Period |

### Wage Types

| # | Name | Expression | Collectors |
|---|---|---|---|
| 100 | GrossSalary | `GetCaseValues("Salary", "EmploymentLevel")["Salary"] * ["EmploymentLevel"]` | GrossIncome |
| 200 | IncomeTax | `WageType[100] * 0.20M` | — |

### Payroll Configuration

```json
"clusterSetWageType": "Legal",
"clusterSetWageTypePeriod": "Legal"
```

`clusterSetWageTypePeriod` activates Custom Result storage for all wage types
in the `Legal` cluster. `clusterSetWageType` controls which wage types run in
the payrun — both point to the same cluster here.

---

## Calculated Results

### January 2025 — no splits

| | Alex Brown | Sam Green |
|---|---|---|
| WT 100 GrossSalary | 4 000.00 (4 000 × 1.0) | 2 880.00 (3 600 × 0.8) |
| WT 200 IncomeTax | 800.00 | 576.00 |
| **GrossIncome** | **4 000.00** | **2 880.00** |

Custom Results Jan (via API):

| Employee | Source | Sub-Period | Value |
|---|---|---|---|
| Alex | `Salary` | Jan 1–31 | 4 000.00 |
| Alex | `EmploymentLevel` | Jan 1–31 | 1.0 |
| Sam | `Salary` | Jan 1–31 | 2 880.00 |
| Sam | `EmploymentLevel` | Jan 1–31 | 0.8 |

### February 2025 — split at Alex Feb 10, Sam Feb 15

| | Alex Brown | Sam Green |
|---|---|---|
| WT 100 GrossSalary | **5 085.71** | **3 240.00** |
| WT 200 IncomeTax | 1 017.14 | 648.00 |
| **GrossIncome** | **5 085.71** | **3 240.00** |

**Alex** — `Salary` changes Feb 10 (28-day month):

| Source | Sub-Period | Days | Calculation | Value |
|---|---|---|---|---|
| `Salary` | Feb 1–9 | 9 | 4 000 × 1.0 × 9/28 | 1 285.71 |
| `Salary` | Feb 10–28 | 19 | 5 600 × 1.0 × 19/28 | 3 800.00 |
| `EmploymentLevel` | Feb 1–28 | 28 | 1.0 (no split) | 1.0 |
| **WT 100 aggregate** | | | 1 285.71 + 3 800.00 | **5 085.71** |

**Sam** — `EmploymentLevel` changes Feb 15:

| Source | Sub-Period | Days | Calculation | Value |
|---|---|---|---|---|
| `Salary` | Feb 1–28 | 28 | 3 600 × … | see note |
| `EmploymentLevel` | Feb 1–14 | 14 | 0.8 (raw value) | 0.8 |
| `EmploymentLevel` | Feb 15–28 | 14 | 1.0 (raw value) | 1.0 |
| **WT 100 aggregate** | | | 3 600×0.8×14/28 + 3 600×1.0×14/28 | **3 240.00** |

> **Note on Salary Custom Result for Sam:** When only `EmploymentLevel` changes
> (Salary is stable), the `Salary` source entry reflects the aggregate wage
> value rather than a prorated sub-period split — the Salary case field itself
> has no boundary in this period.

---

## Key Design Decisions

### `GetCaseValues` for multi-field reads
WT 100 uses `GetCaseValues("Salary", "EmploymentLevel")` to read both fields in
a single call. This is important for `clusterSetWageTypePeriod`: the engine
resolves the combined case value timeline and stores one Custom Result per
resulting sub-period and contributing field.

### `clusterSetWageTypePeriod` = `clusterSetWageType`
Both are set to `Legal`. This means all Legal wage types run normally AND
generate Custom Results. A separate cluster (e.g. `Tracing`) would be used
if only a subset of wage types should produce traceability output.

### Custom Results not assertable in PayrunTest
`payrollResults` in the Exchange format contains only aggregated `wageTypeResults`.
Custom Results must be verified via the REST API or Web App. The expected values
are documented in the tables above.

### `createdObjectDate` for past test data
The root-level `createdObjectDate: "2025-01-01T00:00:00.0Z"` sets the creation
date on all imported objects. Mid-period case changes (Salary Feb 10, Level Feb 15)
override this with explicit `created` dates within the February period, ensuring
they are visible to the Feb 28 evaluation date but not to Jan 31.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.pt.json` | Self-contained payrun test (tenant + regulation + data + assertions) |
| `Delete.pecmd` | Remove the WageTracingPayroll tenant |
| `Test.pecmd` | Delete + run PayrunTest |

## Commands

```
# Run test
Test.pecmd

# Teardown only
Delete.pecmd
```
