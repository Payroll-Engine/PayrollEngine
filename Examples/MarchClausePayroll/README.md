# March Clause Payroll Example

A practical German payroll scenario for **ClearPay GmbH**, demonstrating the
Märzklausel (March clause) — a statutory rule that routes Q1 one-time payments
back to the previous year for social insurance purposes when they exceed the
remaining annual contribution ceiling (BBG).

The detection logic is implemented with **Low-Code extension methods**
(`Scripts/MarchClauseFunctions.cs`). The wage type expression remains a
single method call. Retro scheduling is documented as production-only behavior.

---

## Background — Märzklausel (§ 23a SGB IV)

When a one-time payment (e.g. an annual bonus) is made in January, February,
or March, it is added to the previous year's gross earnings for social insurance
purposes if the sum exceeds the remaining annual BBG (Beitragsbemessungsgrenze).

The check:

```
bonus > 0
AND period is Q1 (January–March)
AND bonus > (BBG limit − previous year earnings)
```

If the condition is met, a retro payrun for December of the previous year must
be triggered so social insurance is recalculated with the bonus attributed to
that year.

---

## Scenario Overview

Two employees in the Operations division. Three monthly payruns (Dec 2024 – Feb 2025).

| Run | Evaluation Date | Events |
|---|---|---|
| Dec 2024 | 2024-12-31 | Salary baseline — no bonus visible |
| Jan 2025 | 2025-01-31 | No bonus visible yet |
| **Feb 2025** | 2025-02-28 | Anna: bonus entered, below remainder → no retro<br />Ben: bonus entered, exceeds remainder → **retro Dec 2024** (production) |

BBG limit: **90 000** (hardcoded in expression; in production read from `Company.BbgLimit` case).

---

## Employees

| Employee | Salary | PreviousYearEarnings | BBG Remainder | Bonus | March Clause |
|---|---|---|---|---|---|
| Anna Weber | 5 000 | 60 000 | **30 000** | 20 000 | 20 000 ≤ 30 000 → **no retro** |
| Ben Kowalski | 7 000 | 84 000 | **6 000** | 12 000 | 12 000 > 6 000 → **retro Dec 2024** |

Anna's bonus (`start: 2025-02-01`) is not active in Dec 2024 → invisible in the retro period.  
Ben's bonus (`start: 2024-01-01`, `created: 2025-02-15`) is active in Dec 2024
and visible from evaluationDate 2025-02-28 onwards.

---

## Regulation: MarchClauseRegulation

### Cases

| Case | Type | Field | Value type | Time type |
|---|---|---|---|---|
| `BbgLimit` | Company | BbgLimit | Money | Timeless |
| `Salary` | Employee | Salary | Money | CalendarPeriod |
| `PreviousYearEarnings` | Employee | PreviousYearEarnings | Money | Timeless |
| `AnnualBonus` | Employee | AnnualBonus | Money | Period |

`PreviousYearEarnings` is Timeless — set once per year after year-end closing.  
`AnnualBonus` uses `timeType: Period` to allow a `start` date in the previous year
while remaining invisible until `created ≤ evaluationDate`.

### Wage Types

| # | Name | Expression | Collectors |
|---|---|---|---|
| 100 | MonthlySalary | `^^Salary` (No-Code) | GrossIncome |
| 200 | AnnualBonus | `return this.GetMarchClauseBonus(90000m);` (Low-Code) | GrossIncome |
| 300 | SocialSecurity | `(^$MonthlySalary + ^$AnnualBonus) * 0.10` (No-Code) | Deductions |

**Production valueExpression for WT 200** (not used in Exchange import):
```csharp
if (!IsRetroPayrun && this.NeedsMarchClauseRetro(90000m))
    ScheduleRetroPayrun(new DateTime(PeriodStart.Year - 1, 12, 1));
return this.GetMarchClauseBonus(90000m);
```

### Collectors

| Collector | Contains |
|---|---|
| GrossIncome | WT 100 + WT 200 |
| Deductions | WT 300 |

---

## Extension Methods — `Scripts/MarchClauseFunctions.cs`

| Method | Returns | Purpose |
|---|---|---|
| `IsMarchClausePeriod()` | `bool` | True if period month is 1–3 |
| `GetBbgRemainder(bbgLimit)` | `decimal` | `Max(0, bbgLimit − PreviousYearEarnings)` |
| `NeedsMarchClauseRetro(bbgLimit)` | `bool` | True if all three March clause conditions are met |
| `GetMarchClauseBonus(bbgLimit)` | `decimal` | Returns `AnnualBonus` case value (pure, no side effects) |

All methods are extension methods on `WageTypeValueFunction` — they can be called
directly in `valueExpression` as `this.MethodName(...)`.

---

## Retro Scheduling Pattern

`ScheduleRetroPayrun()` must not be called during an Exchange import payrun
invocation — the scheduled job cannot start while the current import job is running
(deadlock). This example uses the Exchange import for testing; the production pattern
is documented in the `valueExpression` comment.

| Context | Retro trigger |
|---|---|
| Exchange import test | No retro — `ScheduleRetroPayrun()` omitted |
| Production | `ScheduleRetroPayrun()` in `valueExpression` with `!IsRetroPayrun` guard |

---

## Calculated Results

### December 2024 (baseline — no bonus visible)

| | Anna Weber | Ben Kowalski |
|---|---|---|
| WT 100 MonthlySalary | 5 000 | 7 000 |
| WT 200 AnnualBonus | 0 | 0 |
| WT 300 SocialSecurity | 500 | 700 |
| **GrossIncome** | **5 000** | **7 000** |
| **Deductions** | **500** | **700** |

### January 2025 (no bonus visible — created dates not yet reached)

Identical to December 2024.

### February 2025

| | Anna Weber | Ben Kowalski |
|---|---|---|
| WT 100 MonthlySalary | 5 000 | 7 000 |
| WT 200 AnnualBonus | **20 000** | **12 000** |
| WT 300 SocialSecurity | 2 500 | 1 900 |
| **GrossIncome** | **25 000** | **19 000** |
| **Deductions** | **2 500** | **1 900** |
| March clause | ✗ below remainder | ✓ exceeds remainder → retro in production |

---

## Key Design Decisions

### Period time type for AnnualBonus
`timeType: Period` with an open start date (`start: 2024-01-01`) makes Ben's bonus
active in the Dec 2024 retro period while remaining invisible until
`created (2025-02-15) ≤ evaluationDate (2025-02-28)`. This is the standard engine
pattern for late-entered payments that must be attributed to a past period.

### Extension methods for pure calculation
`NeedsMarchClauseRetro()` and `GetMarchClauseBonus()` are pure functions — no side
effects, no `ScheduleRetroPayrun()` call. This keeps the extension methods testable
and reusable. Retro scheduling remains the responsibility of the `valueExpression`
in the wage type, which has access to `IsRetroPayrun` and the full payrun context.

### Exchange import limitation
`ScheduleRetroPayrun()` in a `valueExpression` causes a deadlock in Exchange import
payrun invocations — the scheduled job queues but cannot start until the import job
finishes, which waits for all jobs to complete. For tests via Exchange import, omit
the `ScheduleRetroPayrun()` call entirely.

### PreviousYearEarnings as Timeless case
`PreviousYearEarnings` is set once after year-end. Using `Timeless` (rather than
`Period` or `CalendarPeriod`) avoids period-boundary ambiguity and makes the value
always available regardless of which period is evaluated.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.mc.yaml` | Complete self-contained payroll test (tenant + regulation + data + results) |
| `Scripts/MarchClauseFunctions.cs` | Low-Code extension methods for BBG calculation |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the ClearPay tenant |
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
