# ForecastPayroll Example

A practical forecast payroll scenario for **PlanSoft GmbH**, demonstrating
forecast payrun isolation and two parallel what-if scenarios.

HR plans to evaluate two options for Q1 2026 — a salary increase or a monthly
bonus — without touching production payroll data. Each scenario runs as an
independent forecast over a three-month planning horizon.

The regulation is fully implemented with **No-Code actions** — no C# scripting required.

---

## Scenario Overview

One employee, one production payrun, two parallel forecast scenarios, each
covering January through March 2026.

| Run | Type | Forecast | Events |
|---|---|---|---|
| Jan 2026 | Production | — | Baseline — salary 5 000 |
| Jan–Mar 2026 | Forecast | `SalaryIncrease2026` | Salary raised to 6 000 |
| Jan–Mar 2026 | Forecast | `BonusScenario2026` | Salary unchanged, bonus 500/month |

---

## Employee

| Employee | Salary | Notes |
|---|---|---|
| Sophie Kramer | 5 000 | Production baseline |

---

## Regulation: ForecastRegulation

### Cases

| Case | Type | Field | Value type | Time type | Actions |
|---|---|---|---|---|---|
| `Salary` | Employee | Salary | Money | CalendarPeriod | Build: `Range(500, 25000)` |
| `PlannedBonus` | Employee | PlannedBonus | Money | CalendarPeriod | Build: `Range(0, 10000)` |

**Case Actions:**
- `Salary.buildActions`: `Range` clamps input to [500, 25 000].
- `PlannedBonus.buildActions`: `Range` clamps input to [0, 10 000].

### Wage Types

| # | Name | Value Actions | Collectors | Clusters |
|---|---|---|---|---|
| 100 | BaseSalary | `^^Salary` | GrossIncome | Legal |
| 110 | PlannedBonus | `? ^^PlannedBonus > 0`<br />`^^PlannedBonus` | GrossIncome | Legal |
| 200 | IncomeTax | `(^$BaseSalary + ^$PlannedBonus) * 0.20` | Deductions | Legal |
| 210 | SocialContribution | `(^$BaseSalary + ^$PlannedBonus) * 0.08` | Deductions | Legal |
| 300 | NetSalary | `^$BaseSalary + ^$PlannedBonus - ^$IncomeTax - ^$SocialContribution` | — | Legal |

**Action references used:**
- `^^` — Case value (reads forecast-tagged data when running inside a forecast job)
- `^$<n>` — Period wage type value — reads the result already computed in the same payrun

**WT 110 value actions:** The condition guard `? ^^PlannedBonus > 0` stops the action
chain when no bonus is planned. `CalendarPeriod` returns `0` for periods with no value
entered — no `HasValue` guard is needed.

**WT 300 NetSalary:** Not assigned to any collector. It acts as the single
bottom-line figure HR reads when comparing scenarios.

---

## Forecast Data

Forecast case data is tagged with a scenario name and is invisible to
production payruns. Two scenarios are entered in parallel:

| Scenario | Case | Value | Period |
|---|---|---|---|
| `SalaryIncrease2026` | Salary | 6 000 | from Jan 2026 |
| `BonusScenario2026` | PlannedBonus | 500 | Jan–Mar 2026 |

Both scenarios share the same `ForecastRegulation` and the same payrun.
They run independently — the engine selects each scenario's case data by
matching the `forecast` name on the payrun job invocation.

---

## Calculated Results

### Scenario comparison — per period (all three months identical)

| | Production | `SalaryIncrease2026` | `BonusScenario2026` |
|---|---|---|---|
| WT 100 BaseSalary | 5 000 | **6 000** | 5 000 |
| WT 110 PlannedBonus | 0 | 0 | **500** |
| **GrossIncome** | **5 000** | **6 000** | **5 500** |
| WT 200 IncomeTax (20 %) | 1 000 | 1 200 | 1 100 |
| WT 210 SocialContribution (8 %) | 400 | 480 | 440 |
| **Deductions** | **1 400** | **1 680** | **1 540** |
| WT 300 NetSalary | **3 600** | **4 320** | **3 960** |

### Three-month totals

| | Production | `SalaryIncrease2026` | `BonusScenario2026` |
|---|---|---|---|
| NetSalary Q1 | 10 800 | 12 960 | 11 880 |
| Additional cost Q1 | — | +2 160 | +1 080 |

---

## Key Design Decisions

### Forecast data isolation
Production and forecast case values coexist in the same regulation and payroll.
The `forecast` tag on a case change record makes it invisible to production
payruns. The forecast payrun job activates the matching scenario by name.

### Parallel scenarios with a single regulation
Both scenarios reuse `ForecastRegulation` unchanged. No regulation override
or separate payroll is needed. Running any number of forecast scenarios in
parallel is a core engine capability.

### No-Code condition guard on PlannedBonus
WT 110 uses the same `? condition / value` two-action pattern as `PartTimePayroll`.
The guard `? ^^PlannedBonus > 0` means:
- **Production run**: no bonus case data → `^^PlannedBonus` = 0 → guard stops → no result.
- **SalaryIncrease2026**: no bonus case data in this scenario → same behavior.
- **BonusScenario2026**: `^^PlannedBonus` = 500 → guard passes → WT 110 = 500.

### `^^` reads scenario-scoped case data
Inside a forecast payrun job, `^^Salary` resolves the case value for the active
forecast name first. If a forecast-tagged value exists it takes precedence over
the production value. `SalaryIncrease2026` therefore sees salary 6 000 while
the production run sees 5 000.

### NetSalary as dedicated forecast output
WT 300 exists specifically to expose the net bottom line without a collector
aggregation step. HR reads WT 300 directly from the forecast result grid.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.fp.yaml` | Complete self-contained payroll test (tenant + regulation + data + results) |
| `BestPractices.md` | Forecast patterns and design decisions |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the PlanSoft tenant |
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
