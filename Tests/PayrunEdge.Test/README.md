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
| `Jun24.EvalStart` | Jun 2024 | **Jun 1 = PeriodStart** | Edge: evalDate == PeriodStart. WageType created=Jun1 visible (`<=`); CaseValue created=Jun1 not visible (strict `<`) |
| `Jul24.EvalEnd` | Jul 2024 | **Jul 31 = last day of period** | Edge: evalDate == last day of period; `EvaluationDate.Day = 31` |
| `Dec24.CycleEnd` | Dec 2024 | **Dec 31 = CycleEnd** | Edge: evalDate == last day of the yearly cycle; `EvaluationDate.Day = 31` |
| `Aug24.Forecast` | Aug 2024 | Jul 28 | **Forecast** `EdgeForecast`: period is ahead of evalDate; `IsForecastIndicator = 1` |

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
| 108 | EvalDateEdgeCaseValue | Legal | CaseValue `created == evaluationDate`: not visible (strict `<`) → 0 |
| 109 | EvalDateEdgeWageType | Legal | WageType `created == evaluationDate` (Jun 1): visible (`<=`) → 42 |
| 202 | BaseSalaryRetroDiff | Legal | `GetWageTypeRetroResultSum(101)` — Mar24: +1000 (4000 − 3000) |

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
```

### CaseValue visibility uses strict `<`

```
EvalDateEdgeValue.created = Jun 1 2024
evalDate Jun = Jun 1  =>  Jun1 < Jun1  is false  =>  not visible  =>  WT108 = 0
evalDate Jul = Jul 31 =>  end=Jun30 (inclusive)  =>  not active in Jul  =>  WT108 = 0
```

This asymmetry is by design: a case value entered on a given day is not yet
visible to a payrun evaluated on the same day; a wage type created on that day
is already part of the regulation and is derived.

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
