# MinWage Payroll Example

A practical minimum wage compliance scenario for **FairPay GmbH**, demonstrating
automatic pay top-up for hourly workers whose agreed rate falls below the statutory
minimum.

The regulation uses a versioned year-lookup for the minimum wage rate and is fully
implemented with **No-Code actions** — no C# scripting required.

---

## Scenario Overview

Two hourly employees in the Logistics division. Two monthly payruns (Jan–Feb 2026).
Leo starts below the statutory minimum and receives a top-up in January. After a
rate increase in February the top-up no longer applies.

| Run | Evaluation Date | Events |
|---|---|---|
| Jan 2026 | 2026-01-31 | Leo 14.50/h — below minimum (15.00) → top-up +80 |
| Feb 2026 | 2026-02-28 | Leo raised to 16.00/h — above minimum → no top-up |

---

## Employees

| Employee | Hourly Rate (Jan) | Hourly Rate (Feb) | Notes |
|---|---|---|---|
| Leo Brandt | 14.50 | **16.00** | Below minimum in Jan, raised in Feb |
| Mia Fischer | 17.00 | 17.00 | Always above minimum |

Hours worked: 160 h/month for both employees.

---

## Regulation: MinWageRegulation

### Lookup: MinimumWage

Single-record lookup keyed by year. Add a new entry annually to version the
statutory rate — no regulation change required.

| Key | HourlyRate |
|---|---|
| `"2026"` | 15.00 |

Access in actions: `^#MinimumWage(PeriodStartYear)`

### Cases

| Case | Type | Field | Value type | Time type | Actions |
|---|---|---|---|---|---|
| `HourlyRate` | Employee | HourlyRate | Money | CalendarPeriod | Build: `Range(8, 100)` |
| `HoursWorked` | Employee | HoursWorked | Decimal | CalendarPeriod | Build: `Range(0, 300)` |

### Wage Types

| # | Name | Value Actions | Collectors | Clusters |
|---|---|---|---|---|
| 100 | BasePay | `^^HoursWorked * ^^HourlyRate` | GrossIncome | Legal |
| 110 | MinWageBase | `^^HoursWorked * ^#MinimumWage(PeriodStartYear, 'HourlyRate')` | — | Legal |
| 120 | MinWageTopUp | `? ^$MinWageBase > ^$BasePay`<br />`^$MinWageBase - ^$BasePay` | GrossIncome | Legal |

**Action references used:**
- `^^` — Case value (employee, current period)
- `^#LookupName(key, 'field')` — Single-record lookup field access
- `^$<n>` — Period wage type value (already computed in the same payrun)
- `PeriodStartYear` — Built-in runtime integer for the current payrun year

**WT 120 MinWageTopUp:** The condition guard `? ^$MinWageBase > ^$BasePay` stops
the action chain when the agreed pay already meets the minimum. The result is 0
(stored via `storeEmptyResults`) for compliant employees — making it directly
queryable as a compliance flag: any non-zero result signals a top-up was applied.

**WT 110 MinWageBase:** Not assigned to a collector. It is an intermediate
value consumed only by WT 120 via `^$MinWageBase`. Excluding it from collectors
keeps `GrossIncome` clean.

---

## Calculated Results

| | Jan — Leo | Jan — Mia | Feb — Leo | Feb — Mia |
|---|---|---|---|---|
| HourlyRate | 14.50 | 17.00 | **16.00** | 17.00 |
| WT 100 BasePay | 2 320 | 2 720 | 2 560 | 2 720 |
| WT 110 MinWageBase | 2 400 | 2 400 | 2 400 | 2 400 |
| WT 120 MinWageTopUp | **80** | 0 | 0 | 0 |
| **GrossIncome** | **2 400** | **2 720** | **2 560** | **2 720** |

---

## Key Design Decisions

### Year-versioned lookup for statutory rates
The minimum wage is stored as a single-record lookup entry per year. HR adds a new
entry when the statutory rate changes — the regulation itself does not need to be
updated. `PeriodStartYear` as the lookup key ensures the correct rate is selected
automatically for every payrun period.

### `^$` references in the top-up wage type
WT 120 reads `^$MinWageBase` and `^$BasePay` — the values already computed by
WT 110 and WT 100 in the same payrun. This avoids duplicating the calculation
and ensures a single source of truth. Wage types are processed in numerical order
(100 → 110 → 120), so the referenced values are always available.

### MinWageBase excluded from collectors
WT 110 is an intermediate calculation, not a pay component. Assigning it to
`GrossIncome` would double-count the base pay. Leaving it without a collector
makes the wage type result queryable for audits without affecting the pay total.

### Compliance signal via storeEmptyResults
`storeEmptyResults: true` on the payrun job stores a 0 result for WT 120 whenever
the top-up guard fails. Payroll compliance tools can query all WT 120 results:
any non-zero value identifies an employee whose agreed rate was below the minimum
in that period.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.mw.yaml` | Complete self-contained payroll test (tenant + regulation + data + results) |
| `BestPractices.md` | Lookup and compliance patterns |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the FairPay tenant |
| `Test.pecmd` | Delete + run PayrunTest |

## Commands

```
# Full setup
Setup.pecmd

# Run test
Test.pecmd

# Teardown
Delete.pecmd
```
