# PayrunEdge.Test

Payrun edge-case tests covering all critical date boundaries, case value time-data patterns,
retro and forecast scenarios.

## Jobs

| Job | Period | EvaluationDate | Scenario |
|:----|:-------|:---------------|:---------|
| `Jan24` | Jan 2024 | Jan 28 | Baseline — CalendarPeriod boundary; SplitBonus not yet active |
| `Feb24` | Feb 2024 | Feb 28 | SplitBonus active from Feb 15; retro change (created=Mar5) not yet visible |
| `Mar24` | Mar 2024 | Mar 28 | **Retro** triggered for Feb: BaseSalary 4000 (created=Mar5) now visible |
| `Apr24` | Apr 2024 | Apr 28 | **Touching**: Supplement switches at Apr 1. **Overlap**: 600 wins over 500 |
| `Jun24.EvalStart` | Jun 2024 | **Jun 1 = PeriodStart** | Edge: evalDate == PeriodStart. CaseValue created=Jun1 not visible (strict `<`); WageType created=Jun1 IS derived (`<=`) |
| `Jul24.EvalEnd` | Jul 2024 | **Jul 31 = last day** | Edge: evalDate == last day of period; WT110 not derived (created=Sep1 > Jul31) |
| `Dec24.CycleEnd` | Dec 2024 | **Dec 31 = CycleEnd** | Edge: evalDate == last day of the yearly cycle; WT110 derived and CaseValue active |
| `Aug24.Forecast` | Aug 2024 | Jul 28 | **Forecast** `EdgeForecast`: period ahead of evalDate; WT110 not derived (created=Sep1 > Jul28) |
| `Sep24.StartEqualsEval` | Sep 2024 | **Sep 1 = PeriodStart** | **Bug fix**: CaseValue Start == EvaluationDate. created=Aug15 (`<` evalDate), start=Sep1 (`==` evalDate). Fix: `Start <= EvalDate` makes value visible → WT110 = 7777 |
| `Oct24.ValidFrom` | Oct 2024 | Oct 28 | **Bug fix**: Regulation `ValidFrom == PeriodEnd`. PeriodEnd(Oct) = `2024-10-31T23:59:59.9999999`. Before fix: `ValidFrom < PeriodEnd` = false → not loaded → WT111 missing. After fix: `ValidFrom <= PeriodEnd` = true → loaded → WT111 = 111 |

## Case Values

| Case | Field | TimeType | Value | Start | End | created | What is tested |
|:-----|:------|:---------|------:|:------|:----|:--------|:---------------|
| BaseSalary | `BaseSalary` | CalendarPeriod | 3000 | Jan 1 | — | Dec 1 '23 | Initial value |
| BaseSalary | `BaseSalary` | CalendarPeriod | 4000 | Feb 1 | — | **Mar 5 '24** | **Retro**: invisible at evalDate=Feb28; visible from Mar28 onwards |
| BaseSalary | `BaseSalary` | CalendarPeriod | 5000 | Mar 1 | — | **Mar 6 '24** | Supersedes 4000: later `start` wins; later `created` confirms priority |
| Supplement | `Supplement` | Period | 100 | Jan 1 | **Apr 1** | Dec 1 '23 | Touching part A |
| Supplement | `Supplement` | Period | 200 | **Apr 1** | — | Dec 2 '23 | Touching part B: `start == end(A)` |
| SplitBonus | `SplitBonus` | Period | 300 | **Feb 15** | — | Feb 15 '24 | Mid-period split: value starts on the 15th |
| OverlapAllowance | `OverlapAllowance` | CalendarPeriod | 500 | Apr 1 | May 1 | **Mar 1 '24** | Overlap: older entry |
| OverlapAllowance | `OverlapAllowance` | CalendarPeriod | 600 | Apr 1 | May 1 | **Apr 1 '24** | Overlap: newer entry — must win |
| EvalDateEdgeValue | `EvalDateEdgeValue` | CalendarPeriod | 999 | Jun 1 | **Jun 30** | **Jun 1 '24** | `created == evaluationDate` — not visible (strict `<`); `end=Jun30` keeps value out of July |
| StartEqualsEvalSalary | `StartEqualsEvalSalary` | CalendarPeriod | 7777 | **Sep 1** | — | Dec 1 '23 | **Bug fix (CaseValueRepositoryBase)**: `start == evaluationDate`. Fix: `Start <= EvalDate` → visible → 7777. Early created prevents retro side-effects |

## Regulations

| Regulation | ValidFrom | What is tested |
|:-----------|:----------|:---------------|
| `PayrunEdge` | — (always valid) | All main edge cases |
| `PayrunEdge.ValidFrom` | `2024-10-31T23:59:59.9999999` | **Bug fix (GetDerivedRegulations)**: `ValidFrom == PeriodEnd`. Before fix: `ValidFrom < PeriodEnd` = false → not loaded. After fix: `ValidFrom <= PeriodEnd` = true → loaded → WT111 = 111 |

## Wage Types

| WT | Name | Clusters | What is tested |
|---:|:-----|:---------|:---------------|
| 101 | BaseSalary | Legal, **Retro** | CalendarPeriod boundary; recalculated in retro sub-run |
| 102 | Supplement | Legal | Period touching: value switches exactly at period boundary Apr 1 |
| 103 | SplitBonus | Legal | Time-data splitting: Period value active from mid-period (Feb 15) |
| 104 | OverlapAllowance | Legal | Overlapping: two entries for same period; latest `created` wins |
| 105 | EvalDateDay | Legal | `EvaluationDate.Day` — directly observable for edge runs (1 or 31) |
| 106 | IsRetroIndicator | Legal, **Retro** | `IsRetroPayrun` — returns 1 in retro sub-runs, 0 in main runs |
| 107 | IsForecastIndicator | Legal | `!string.IsNullOrEmpty(Forecast)` — returns 1 in forecast runs |
| 108 | EvalDateEdgeCaseValue | Legal | CaseValue `created == evaluationDate`: not visible (strict `<`) → 0. Intentional by-design asymmetry. |
| 109 | EvalDateEdgeWageType | Legal | WageType `created == evaluationDate` (Jun 1): visible (`<=`) → 42 |
| 110 | StartEqualsEvalSalary | Legal | **Bug fix (CaseValueRepositoryBase)**: CaseValue `start == evaluationDate` (Sep 1). created=Sep1 so only derived from evalDate≥Sep1. Before fix: `Start < EvalDate` → 0. After fix: `Start <= EvalDate` → 7777. |
| 111 | ValidFromBoundary | Legal | **Bug fix (GetDerivedRegulations)**: Regulation `ValidFrom == PeriodEnd`. Before fix: `ValidFrom < PeriodEnd` → not loaded → no result. After fix: `ValidFrom <= PeriodEnd` → loaded → 111. Derived for Oct24+ only (PeriodEnd ≥ Oct31 23:59:59.9999999). |
| 202 | BaseSalaryRetroDiff | Legal | `GetWageTypeRetroResultSum(101)` — Mar24: +1000 (4000 − 3000) |

## WT110 / WT111 Derivation Range

WT110 has `created = 2024-09-01` — only derived for payruns with `evaluationDate >= Sep 1 2024`.
WT111 (in regulation `PayrunEdge.ValidFrom`) is only derived when `PeriodEnd >= ValidFrom = 2024-10-31T23:59:59.9999999`:

| Job | EvaluationDate | WT110 derived? | WT110 result |
|:----|:---------------|:---------------|:-------------|
| Jan24–Apr24 | Jan28–Apr28 | No (< Sep1) | — |
| Jun24.EvalStart | Jun 1 | No (< Sep1) | — |
| Jul24.EvalEnd | Jul 31 | No (< Sep1) | — |
| Aug24.Forecast | Jul 28 | No (< Sep1) | — |
| **Sep24.StartEqualsEval** | **Sep 1** | **Yes** (Sep1 <= Sep1) | **7777** |
| **Oct24.ValidFrom** | Oct 28 | Yes | 7777 |
| Dec24.CycleEnd | Dec 31 | Yes | 7777 |

**WT111 derivation** (regulation `PayrunEdge.ValidFrom`, `ValidFrom = 2024-10-31T23:59:59.9999999`):

| Job | PeriodEnd | WT111 derived? | WT111 result |
|:----|:----------|:---------------|:-------------|
| Jan24–Sep24 | Jan31–Sep30 (23:59:59.9999999) | No (< Oct31 23:59:59.9999999) | — |
| **Oct24.ValidFrom** | **Oct31 23:59:59.9999999** | **Yes after fix** (== ValidFrom, `<=`) | **111** |
| Dec24.CycleEnd | Dec31 23:59:59.9999999 | Yes (> ValidFrom) | 111 |

## Retro Mechanics (Mar24)

```
Initial:      BaseSalary Feb = 3000  (evalDate=Feb28 cannot see created=Mar5)
After Mar28:  BaseSalary Feb = 4000  (created=Mar5 <= evalDate=Mar28 => visible)
Retro delta:  4000 - 3000 = +1000   => WT202 = 1000 in main run Mar24
Retro result: WT101 = 4000, WT106 = 1  (retroPeriodStart = Feb 1)
```

## EvaluationDate Edge Semantics

### WageType derivation uses `<=`

```
WT109.created = Jun 1 2024
evalDate Jan  = Jan 28  =>  Jan28 < Jun1   =>  WT109 not derived  (no result)
evalDate Jun  = Jun 1   =>  Jun1  <= Jun1  =>  WT109 derived       (value 42)

WT110.created = Sep 1 2024
evalDate Jul  = Jul 31  =>  Jul31 < Sep1   =>  WT110 not derived  (no result)
evalDate Sep  = Sep 1   =>  Sep1  <= Sep1  =>  WT110 derived       (value 7777)
```

### CaseValue Created visibility uses strict `<` (by design)

```
EvalDateEdgeValue.created = Jun 1 2024
evalDate Jun = Jun 1  =>  Jun1 < Jun1  is false  =>  not visible  =>  WT108 = 0
evalDate Jul = Jul 31 =>  end=Jun30 (inclusive)  =>  not active in Jul  =>  WT108 = 0
```

This asymmetry is **intentional**: a case value entered on a given day is not yet
visible to a payrun evaluated on the same day; a wage type published on that day
is already part of the regulation and is derived.

### CaseValue Start boundary uses `<=` (bug fix — CaseValueRepositoryBase)

```
StartEqualsEvalSalary.created = Dec 1 2023    (always passes Created filter — no retro side-effects)
StartEqualsEvalSalary.start   = Sep 1 2024

evalDate = Sep 1  =>  period.End = Sep 1
  Before fix: Start < period.End  =>  Sep1 < Sep1  = false  =>  NOT in cache  =>  WT110 = 0  (WRONG)
  After fix:  Start <= period.End =>  Sep1 <= Sep1 = true   =>  in cache      =>  WT110 = 7777 (CORRECT)
```

Fixed in `CaseValueRepositoryBase.GetPeriodCaseValuesAsync`:
```csharp
// before: dbQuery.WhereNullOrValue(DbSchema.CaseValueColumn.Start, "<",  period.End);
           dbQuery.WhereNullOrValue(DbSchema.CaseValueColumn.Start, "<=", period.End);
```

### Regulation ValidFrom boundary uses `<=` (bug fix — GetDerivedRegulations)

```
Regulation PayrunEdge.ValidFrom.validFrom = 2024-10-31T23:59:59.9999999
PeriodEnd (Oct 2024)                      = 2024-10-31T23:59:59.9999999  (= AddDays(-1).LastMomentOfDay())

  Before fix: ValidFrom < PeriodEnd  =>  Oct31 23:59:59.9999999 < Oct31 23:59:59.9999999  = false  =>  NOT loaded  =>  WT111 missing  (WRONG)
  After fix:  ValidFrom <= PeriodEnd =>  Oct31 23:59:59.9999999 <= Oct31 23:59:59.9999999 = true   =>  loaded      =>  WT111 = 111    (CORRECT)
```

Fix required in `GetDerivedRegulations` SQL (Create-Model.sql):
```sql
-- before: AND ([Regulation].[ValidFrom] IS NULL OR [Regulation].[ValidFrom] < @regulationDate)
           AND ([Regulation].[ValidFrom] IS NULL OR [Regulation].[ValidFrom] <= @regulationDate)
```

### `end` is inclusive

A case value with `end: 2024-03-01` is still active on March 1, causing a
pro-rata split for CalendarPeriod fields: `(days_before_end × A + 1 × B) / total_days`.
To confine a value to a single calendar month, set `end` to the last day of
that month (e.g. `2024-06-30`) rather than the first day of the next.

### CalendarPeriod priority: `start` first, `created` as tiebreaker

When multiple open-ended CalendarPeriod values overlap for the same field, the
engine selects by: **1. latest `start`**, then **2. latest `created`**.
BaseSalary 5000 (start=Mar1, created=Mar6) supersedes 4000 (start=Feb1,
created=Mar5) because its `start` is later.

## Run

```cmd
PayrunEdge.Test/Test.pecmd
```

Add to `Test.All.pecmd`:

```
PayrunEdge.Test/Test.pecmd
```
