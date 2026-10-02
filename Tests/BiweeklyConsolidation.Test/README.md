# BiweeklyConsolidation.Test

Verifies that `GetConsolidatedWageTypeResults` correctly accumulates YTD totals
across all biweekly pay periods after the `GetPayrollPeriod` step-size fix.

---

## Background — The Platform Fix

`BiWeekPayrollPeriod.GetPayrollPeriod(moment, offset)` previously used
`offset * Date.DaysInWeek` (7 days) instead of `offset * Date.DaysInBiWeek` (14 days).

For en-US calendars where the year starts mid-week (e.g. 2026, Jan 1 = Thursday):
- Biweekly period containing Jan 1 → starts Dec 28, 2025 (week 53, Sunday)
- `GetPayrollPeriod(Dec 28, 1)` with 7-day step → Jan 4, 2026
- Jan 4 = week 2 → biweekly normalization pulls back to Dec 28 (**same start**)
- `GetConsolidatedPeriodStarts` loop never advances → **infinite loop / 100 s timeout**

Fix: `offset * Date.DaysInBiWeek` (14 days). Jan 25 (week 5, odd → no pullback) → correct.

---

## How `WageTypeResult.Start` Is Stored

`PayrunJob.PeriodStart` is set from `GetPayrunPeriod(invocation.periodStart).Start` —
the **calendar biweekly period start**, not the first of the month and not the
raw invocation date.

| Invocation `periodStart` | Calendar period start | `WageTypeResult.Start` |
|:-------------------------|:----------------------|:-----------------------|
| 2026-01-01 (Thu) | **Dec 28, 2025** (Sun, week 53) | Dec 28, 2025 |
| 2026-01-15 (Thu) | **Jan 11, 2026** (Sun, week 3)  | Jan 11, 2026 |
| 2026-01-29 (Thu) | **Jan 25, 2026** (Sun, week 5)  | Jan 25, 2026 |
| 2026-02-12 (Thu) | **Feb 8, 2026**  (Sun, week 7)  | Feb 8, 2026  |
| 2026-02-26 (Thu) | **Feb 22, 2026** (Sun, week 9)  | Feb 22, 2026 |
| 2026-03-12 (Thu) | **Mar 8, 2026**  (Sun, week 11) | Mar 8, 2026  |

All six periods have **distinct** `Start` values → `ROW_NUMBER = 1` for each →
no deduplication. All prior periods are correctly found by `GetConsolidatedPeriodStarts`.

---

## Regulation

| # | Name | Expression |
|--:|:-----|:-----------|
| 101 | `BiweeklyWage` | `CaseValue["BiweeklyWage"]` — flat 1 000 per period (`timeType: Period`) |
| 102 | `ConsolidatedYtd` | `GetConsolidatedWageTypeResults(new(101, CycleStart, PayrunJobStatus.Complete)).Sum(x => x.Value)` |

---

## Expected Results (all PASS)

| Period | PeriodStart (invocation) | PayrunJob.PeriodStart | WT 101 | WT 102 |
|:-------|:-------------------------|:----------------------|-------:|-------:|
| P1 | 2026-01-01 | Dec 28, 2025 | 1 000 | 0 |
| P2 | 2026-01-15 | Jan 11, 2026 | 1 000 | 1 000 |
| P3 | 2026-01-29 | Jan 25, 2026 | 1 000 | 2 000 |
| P4 | 2026-02-12 | Feb 8, 2026  | 1 000 | 3 000 |
| P5 | 2026-02-26 | Feb 22, 2026 | 1 000 | 4 000 |
| P6 | 2026-03-12 | Mar 8, 2026  | 1 000 | 5 000 |

---

## Note on Report-Layer Usage

`GetConsolidatedWageTypeResults` in payrun scripts works correctly for all
biweekly periods because it internally calls `GetConsolidatedPeriodStarts`,
which generates the calendar-aligned biweekly period starts (Dec 28, Jan 11 …).

Report functions that call the same stored procedure **directly** (e.g. W-2,
Form 941) must pass the actual `PayrunJob.PeriodStart` values from completed
jobs — **not** first-of-month dates such as `Enumerable.Range(1, 12)`. Using
first-of-month hashes returns zero results for biweekly employees because the
stored `WageTypeResult.Start` values are biweekly calendar dates, not month
boundaries.

---

## Running the Test

```cmd
cd Tests\BiweeklyConsolidation.Test
pecmd Test.pecmd
```

## See Also

- [ConsolidatedPayroll.Test](../ConsolidatedPayroll.Test/) — monthly YTD baseline
- [ConsolidatedEdge.Test](../ConsolidatedEdge.Test/) — NoRetro flag behaviour
- [WeekCalendar.Test](../WeekCalendar.Test/) — biweekly calendar period configuration
