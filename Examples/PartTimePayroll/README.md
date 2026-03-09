# PartTime Payroll Example

A practical part-time payroll scenario for **FlexWork AG**, demonstrating three
real-world features: employment level scaling, overtime restricted to full-time
employees, and retroactive level corrections.

The entire regulation is implemented with **No-Code actions** — no C# scripting required.

---

## Scenario Overview

Two employees in the Engineering division. Three monthly payruns (Jan–Mar 2025).
One retroactive employment level change triggers a retro correction in the March run.

| Run | Evaluation Date | Events |
|---|---|---|
| Jan 2025 | 2025-01-31 | Baseline — Anna 80%, Mark 100% |
| Feb 2025 | 2025-02-28 | Mark: 8h overtime — Anna: retro not yet visible |
| **Mar 2025** | 2025-03-31 | **Retro** Anna level 80% → 60% effective Feb 1 |

---

## Employees

| Employee | Salary | Level | Notes |
|---|---|---|---|
| Anna Weber | 4 800 | 0.8 → **0.6** (eff. Feb 1) | Level change entered retroactively in March |
| Mark Bauer | 5 000 | 1.0 | Full-time; 8h overtime in February |

---

## Regulation: PartTimeRegulation

### Cases

| Case | Type | Field | Value type | Time type | Actions |
|---|---|---|---|---|---|
| `Salary` | Employee | Salary | Money | CalendarPeriod | Build: `Range(500, 25000)` |
| `EmploymentLevel` | Employee | EmploymentLevel | Percent | Period | Build: `Range(0.1, 1.0)` |
| `OvertimeHours` | Employee | OvertimeHours | Decimal | CalendarPeriod | Available: `? ^^EmploymentLevel >= 1.0` |

**Case Actions:**
- `Salary.buildActions`: `Range` clamps input to [500, 25000].
- `EmploymentLevel.buildActions`: `Range` clamps input to [0.1, 1.0].
- `OvertimeHours.availableActions`: `? ^^EmploymentLevel >= 1.0` — the case is hidden from HR when the employee is part-time.

### Wage Types and Cluster Assignment

| # | Name | Value Actions | Collectors | Clusters |
|---|---|---|---|---|
| 100 | BaseSalary | `^^Salary * ^^EmploymentLevel` | GrossIncome | **Legal, Retro** |
| 102 | BaseSalaryDelta | `GetWageTypeRetroResultSum(100)` | — | Legal |
| 120 | Overtime | `? ^^EmploymentLevel >= 1.0`<br />`^^OvertimeHours * (^^Salary / 160M) * 1.25M` | GrossIncome | **Legal, Retro** |
| 200 | IncomeTax | `(^$BaseSalary + ^$Overtime) * 0.20` | Deductions | **Legal, Retro** |
| 202 | IncomeTaxDelta | `GetWageTypeRetroResultSum(200)` | — | Legal |
| 210 | SocialSecurity | `(^$BaseSalary + ^$Overtime) * 0.08` | Deductions | **Legal, Retro** |
| 212 | SocialSecurityDelta | `GetWageTypeRetroResultSum(210)` | — | Legal |

**Action references used:**
- `^^` — Case value (employee/company/national, any period)
- `^$<n>` — Wage type value of the current period (Memory) — name must be space-free

**WT 120 value actions:** One condition guard executes first. If the employee is part-time, the action chain stops and the wage type produces no result. For `CalendarPeriod` fields, a missing value returns `0` — no `HasValue` guard is needed since `0 * rate = 0`.

### Cluster Sets

| ClusterSet | Role | Includes |
|---|---|---|
| `Legal` | Normal payrun | WT 100, 102, 120, 200, 202, 210, 212 |
| `Retro` | Retro recalculation | WT 100, 120, 200, 210 |

Delta WTs (102, 202, 212) are **Legal only** — they run once in the current period to collect retro corrections via `GetWageTypeRetroResultSum()`, never inside a retro recalculation.

---

## Calculated Results

### January 2025 (baseline)

| | Anna Weber | Mark Bauer |
|---|---|---|
| WT 100 BaseSalary | 3 840 (4800 x 0.8) | 5 000 (5000 x 1.0) |
| WT 120 Overtime | — (conditions fail) | 0 (no OT entered) |
| **GrossIncome** | **3 840** | **5 000** |
| WT 200 IncomeTax (20%) | 768 | 1 000 |
| WT 210 SocialSecurity (8%) | 307.20 | 400 |
| **Deductions** | **1 075.20** | **1 400** |
| WT 102 / 202 / 212 | 0 / 0 / 0 | 0 / 0 / 0 |

### February 2025

Anna's level change (created 2025-03-05) is **not yet visible** — evaluationDate is 2025-02-28. Anna is still paid at 80%.

Mark's overtime (created 2025-02-15 <= evaluationDate 2025-02-28) is visible. OvertimeHours CalendarPeriod start=Feb 1 / end=Feb 28 belongs to the February period.

| | Anna Weber | Mark Bauer |
|---|---|---|
| WT 100 BaseSalary | 3 840 | 5 000 |
| WT 120 Overtime | — | **312.50** (8h x 31.25 x 1.25) |
| **GrossIncome** | **3 840** | **5 312.50** |
| WT 200 IncomeTax | 768 | **1 062.50** |
| WT 210 SocialSecurity | 307.20 | **425** |
| **Deductions** | **1 075.20** | **1 487.50** |

### March 2025

Anna's level change is now visible (created 2025-03-05 <= evaluationDate 2025-03-31).
A retro run for February recalculates Anna at 60%. Mark is unaffected.

**Current period:**

| | Anna Weber | Mark Bauer |
|---|---|---|
| WT 100 BaseSalary | 2 880 (4800 x **0.6**) | 5 000 |
| WT 120 Overtime | — | 0 |
| **GrossIncome** | **2 880** | **5 000** |
| WT 200 IncomeTax | 576 | 1 000 |
| WT 210 SocialSecurity | 230.40 | 400 |
| **Deductions** | **806.40** | **1 400** |
| WT 102 BaseSalaryDelta | **-960** | 0 |
| WT 202 IncomeTaxDelta | **-192** | 0 |
| WT 212 SocialSecurityDelta | **-76.80** | 0 |

**Retro period — Anna, February (recalculated at 60%):**

| WT 100 | WT 200 | WT 210 |
|---|---|---|
| 2 880 | 576 | 230.40 |

Delta vs stored Feb: WT 100 -960, WT 200 -192, WT 210 -76.80 — Anna was overpaid at 80%.

---

## Key Design Decisions

### No-Code action implementation
The entire regulation uses No-Code actions — no C# `valueExpression`. Integrated
functions such as `GetWageTypeRetroResultSum()` can be called directly from `valueActions`,
making delta wage types fully No-Code.

### Overtime guarded by employment level condition
WT 120 uses one condition guard before the calculation:
```
? ^^EmploymentLevel >= 1.0
^^OvertimeHours * (^^Salary / 160M) * 1.25M
```
If the employee is part-time, the action chain stops and WT 120 produces no result.
For `CalendarPeriod` fields, a missing value returns `0` — no `HasValue` guard is needed.
The `OvertimeHours` case additionally has `availableActions: ["? ^^EmploymentLevel >= 1.0"]`
— hiding the case from HR is a separate, independent guard at the data-entry level.

### `^$<n>` for wage type references in deductions
WT 200 and WT 210 use `^$BaseSalary` and `^$Overtime` (period wage type values) instead
of `^^` (case values) or the collector. The `^$` reference reads the value already
computed by the wage type in the current payrun period — correct in both normal and retro
runs. Note that `^$` names must be space-free — hence `BaseSalary` rather than `Base Salary`.

### Retro visibility controlled by evaluationDate
Anna's level change has `created: 2025-03-05`. It is invisible to the February run
(evaluationDate 2025-02-28) and visible to the March run (evaluationDate 2025-03-31).
The February run correctly pays Anna at 80% with no retro. The March run triggers the
retro correction automatically.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.pt.yaml` | Complete self-contained payroll test (tenant + regulation + data + results) |
| `BestPractices.md` | No-Code action patterns and design decisions |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the FlexWork tenant |
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
