# Retro Payroll Example

A practical retro payroll scenario for **RetroPayroll AG**, demonstrating three
real-world situations that trigger retroactive payroll corrections across multiple
periods.

---

## Scenario Overview

Two employees in the Engineering division. Four monthly payruns (Jan–Apr 2024).
Three retroactive events create retro corrections in the March and April runs.

| Run | Evaluation Date | Retro Events |
|---|---|---|
| Jan 2024 | 2024-01-31 | none — baseline |
| Feb 2024 | 2024-02-29 | none — baseline |
| **Mar 2024** | 2024-03-31 | **A** Emma raise (Jan+Feb) · **B** Ben bonus (Jan) |
| **Apr 2024** | 2024-04-30 | **C** Emma part-time reduction (Feb+Mar) — negative deltas |

---

## Employees

| Employee | Salary | Level | Notes |
|---|---|---|---|
| Emma Bauer | 4 800 → **5 800** (eff. Jan) | 1.0 → **0.8** (eff. Feb) | Both changes entered retroactively |
| Ben Kowalski | 6 000 | 0.5 | Q4 bonus 1 500 entered late in March |

---

## Regulation: RetroRegulation

### Cases

| Case | Type | Field | Value type | Time type |
|---|---|---|---|---|
| `Salary` | Employee | Salary | Money | CalendarPeriod |
| `EmploymentLevel` | Employee | EmploymentLevel | Percent | Period |
| `Bonus` | Employee | Bonus | Money | **Moment** |

### Wage Types and Cluster Assignment

| # | Name | Expression | Collectors | Clusters |
|---|---|---|---|---|
| 100 | Base Salary | `Salary × EmploymentLevel` | Gross Income | **Legal, Retro** |
| 102 | Retro Delta – Base Salary | `GetWageTypeRetroResultSum(100)` | — | Legal |
| 110 | Bonus | `CaseValue["Bonus"]` | Gross Income | **Legal, Retro** |
| 112 | Retro Delta – Bonus | `GetWageTypeRetroResultSum(110)` | — | Legal |
| 200 | Income Tax | `(WageType[100] + WageType[110]) × 25 %` | Deductions | **Legal, Retro** |
| 202 | Retro Delta – Income Tax | `GetWageTypeRetroResultSum(200)` | — | Legal |
| 210 | Social Security | `(WageType[100] + WageType[110]) × 10 %` | Deductions | **Legal, Retro** |
| 212 | Retro Delta – Social Security | `GetWageTypeRetroResultSum(210)` | — | Legal |

### Cluster Sets

| ClusterSet | Role | Includes |
|---|---|---|
| `Legal` | Normal payrun | WT 100, 102, 110, 112, 200, 202, 210, 212 |
| `Retro` | Retro recalculation | WT 100, 110, 200, 210 |

```json
"clusterSetWageType":      "Legal",
"clusterSetWageTypeRetro": "Retro"
```

Delta WTs (102, 112, 202, 212) are **Legal only** — they are never re-executed in a
retro run, only in the current normal period where they collect the accumulated diff.

---

## Retro Events

### Event A — Emma: Retroactive Salary Raise (March run)

| | |
|---|---|
| Entered | 2024-03-10 (visible in Mar evaluation 2024-03-31) |
| Effective from | 2024-01-01 |
| Old salary | 4 800 |
| New salary | **5 800** |
| Retro periods triggered | Jan 2024, Feb 2024 |

The engine detects that salary changed in periods that have already been paid and
reruns those periods with the new value. The delta is collected in the March run.

### Event B — Ben: Late Bonus Entry (March run)

| | |
|---|---|
| Entered | 2024-03-08 (visible in Mar evaluation 2024-03-31) |
| Bonus Moment | 2024-01-15 → belongs to January period |
| Amount | **1 500** |
| Retro periods triggered | Jan 2024 |

The `Moment` time type places the bonus in the period containing 2024-01-15.
Because January has already been paid, the engine creates a retro run for Jan.

### Event C — Emma: Retroactive Part-Time Reduction (April run)

| | |
|---|---|
| Entered | 2024-04-05 (visible in Apr evaluation 2024-04-30) |
| Effective from | 2024-02-01 |
| Old level | 1.0 |
| New level | **0.8** |
| Retro periods triggered | Feb 2024, Mar 2024 |

The stored retro values for Feb (updated by Event A) and the normal Mar values are
now higher than the correct values. The deltas are **negative** — the employee was
overpaid relative to the correct 80 % level.

---

## Calculated Results — January 2024 (baseline)

No retro. Bonus not yet entered (created 2024-03-08 > evaluationDate 2024-01-31).

| | Emma Bauer | Ben Kowalski |
|---|---|---|
| WT 100 Base Salary | 4 800 (4800 × 1.0) | 3 000 (6000 × 0.5) |
| WT 110 Bonus | — | — (not entered yet) |
| **Gross Income** | **4 800** | **3 000** |
| WT 200 Income Tax (25 %) | 1 200 | 750 |
| WT 210 Social Security (10 %) | 480 | 300 |
| **Deductions** | **1 680** | **1 050** |
| WT 102 / 112 / 202 / 212 | 0 | 0 |

---

## Calculated Results — February 2024 (baseline)

Identical to January 2024. No retro.

---

## Calculated Results — March 2024

### Current Period (normal run)

| | Emma Bauer | Ben Kowalski |
|---|---|---|
| WT 100 Base Salary | 5 800 (raised salary) | 3 000 |
| WT 110 Bonus | — | 0 (bonus Moment = Jan, not March) |
| **Gross Income** | **5 800** | **3 000** |
| WT 200 Income Tax | 1 450 | 750 |
| WT 210 Social Security | 580 | 300 |
| **Deductions** | **2 030** | **1 050** |
| WT 102 Retro Δ salary | **+2 000** | 0 |
| WT 112 Retro Δ bonus | 0 | **+1 500** |
| WT 202 Retro Δ tax | **+500** | **+375** |
| WT 212 Retro Δ ss | **+200** | **+150** |

### Retro Period Results (recalculated, stored, used for delta computation)

**Emma — Retro January**

| WT 100 | WT 200 | WT 210 |
|---|---|---|
| 5 800 | 1 450 | 580 |

Delta vs stored Jan: WT100 +1 000, WT200 +250, WT210 +100

**Emma — Retro February**

| WT 100 | WT 200 | WT 210 |
|---|---|---|
| 5 800 | 1 450 | 580 |

Delta vs stored Feb: WT100 +1 000, WT200 +250, WT210 +100

**Ben — Retro January**

| WT 110 | WT 200 | WT 210 |
|---|---|---|
| **1 500** | 1 125 | 450 |

Delta vs stored Jan: WT110 +1 500, WT200 +375, WT210 +150

> WT 100 is absent: Ben's salary did not change retroactively. Only the newly entered
> bonus (WT 110) triggers a retro correction. The engine only persists wage types that
> produce a result in the retro run.

---

## Calculated Results — April 2024

### Current Period (normal run)

| | Emma Bauer | Ben Kowalski |
|---|---|---|
| WT 100 Base Salary | 4 640 (5800 × **0.8**) | 3 000 |
| WT 110 Bonus | — | 0 |
| **Gross Income** | **4 640** | **3 000** |
| WT 200 Income Tax | 1 160 | 750 |
| WT 210 Social Security | 464 | 300 |
| **Deductions** | **1 624** | **1 050** |
| WT 102 Retro Δ salary | **−2 320** | 0 |
| WT 202 Retro Δ tax | **−580** | 0 |
| WT 212 Retro Δ ss | **−232** | 0 |

### Retro Period Results (Emma, April run)

The "old stored" Feb and Mar values already reflect Event A (salary = 5 800, level = 1.0).
The new retro recalculation applies the corrected level 0.8 → **smaller values → negative deltas**.

**Emma — Retro February (2nd correction)**

| WT 100 | WT 200 | WT 210 |
|---|---|---|
| 4 640 | 1 160 | 464 |

Delta vs stored Feb: WT100 −1 160, WT200 −290, WT210 −116

**Emma — Retro March**

| WT 100 | WT 200 | WT 210 |
|---|---|---|
| 4 640 | 1 160 | 464 |

Delta vs stored Mar: WT100 −1 160, WT200 −290, WT210 −116

---

## Key Design Decisions

### ClusterSets: separating normal and retro execution
Only WTs in the `Retro` cluster are re-executed during retro runs. The delta WTs
(102, 112, 202, 212) must be **Legal only** — if they were in the Retro cluster, they
would be re-evaluated in each retro period and produce wrong intermediate totals.

### Moment vs CalendarPeriod for Bonus
`timeType: Moment` places the bonus in exactly one pay period based on its date.
This is what makes late bonus entry automatically trigger a retro run for the correct
historical period rather than appearing in the current month.

### storeEmptyResults: true
Required on all payrun jobs that precede retro runs. Without stored baseline results,
`GetWageTypeRetroResultSum()` has no "old value" to diff against and returns 0.

### Cascading retro corrections
Event C (April) corrects values that Event A (March) had already corrected. The engine
always diffs against the **most recently stored value**, so each correction layer is
exact regardless of how many prior corrections exist.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.pt.json` | Complete self-contained payroll test (tenant + regulation + data + results) |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the RetroPayroll tenant |
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
