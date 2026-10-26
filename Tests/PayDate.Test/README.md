# PayDate.Test

Verifies the payrun job pay date, the calendar cycle assignment, the regulation date
and bi-weekly periods anchored by the calendar period anchor date.

## Scenario

**Regulations:** `PayDate.Test` (layer 1), `PayDate.Test.2027` (layer 2, valid from 2027-01-01)  
**Division:** `PayDate.Division` (en-US) | **Employee:** `remo.meier@foo.com`

| File | Tenant | `cycleAssignment` |
|:-----|:-------|:------------------|
| `Test.pt.json` | `PayDate.Test` | `PayDate` |
| `PeriodEnd.pt.json` | `PayDate.PeriodEnd.Test` | `PeriodEnd` |

Both files use the same regulations, case values and payrun jobs. The cycle assignment
determines the cycle (tax year) of a period and the regulation date:

| `cycleAssignment` | Cycle date | Regulation date |
|:------------------|:-----------|:----------------|
| `PayDate` (default) | Job pay date | Job pay date (end of day) |
| `PeriodEnd` | Period end | Period end |

### Calendar

| Property | Value | Effect |
|:---------|:------|:-------|
| `cycleTimeUnit` | Year | |
| `periodTimeUnit` | BiWeek | 14-day periods |
| `periodAnchorDate` | 2026-01-04 (Sunday) | Periods start on 2026-01-04 + n × 14 days, in both directions |
| `payDateOffset` | 5 | Pay date = period end date + 5 days |
| `cycleAssignment` | PayDate / PeriodEnd | Date assigning the period to the cycle and the regulation |

### Wage Types

| # | Name | Clusters | Purpose |
|--:|:-----|:---------|:--------|
| 100 | PeriodStartDate | Legal, Retro | Period start as `yyyymmdd` |
| 101 | PeriodEndDate | Legal, Retro | Period end as `yyyymmdd` |
| 102 | PayDate | Legal, Retro | Pay date as `yyyymmdd` |
| 103 | RegulationYear | Legal, Retro | `2026`, overridden with `2027` by `PayDate.Test.2027` |
| 104 | CycleYear | Legal, Retro | `CycleStart.Year` |
| 105 | CycleSalary | Legal, Retro | Consolidated WT110 of the previous cycle periods (year to date) |
| 106 | FirstCyclePeriod | Legal, Retro | `1` for the first period of the cycle, otherwise `0` |
| 107 | PeriodsInCycle | Legal, Retro | Number of periods in the cycle |
| 108 | PeriodTimeUnit | Legal, Retro | Calendar period time unit as number of periods per year (`26` for BiWeek) |
| 109 | TimeMap | Legal, Retro | Calendar time map (`0` Period, `1` Cycle; `1` for `BiWeekAnchored`) |
| 110 | Salary | Legal, Retro | `CaseValue["Salary"]` |
| 111 | SalaryRetroDiff | Legal | Retro delta: `GetWageTypeRetroResultSum(110)` |
| 120 | RetroPayDate | Legal, Retro | Pay date as `yyyymmdd` in retro runs, `0` in main runs |
| 121 | RetroRegulationYear | Legal, Retro | Regulation year in retro runs (`2026` / `2027`), `0` in main runs |

Retro jobs store changed results only: wage types 120 and 121 make the pay date and
the regulation selection of the retro runs visible.

### Case Values

| Field | Value | Start | Created |
|:------|------:|:------|:--------|
| Salary | 1000 | 2025-12-01 | 2025-11-15 |
| Salary | **1500** | 2026-12-06 | **2027-01-10** |

The second value changes the salary retroactively from 2026-12-06 and becomes
visible with the evaluation date of the last job.

## Payrun Jobs

| Job | Invocation | Period | Pay date | Regulation year | Salary |
|:----|:-----------|:-------|:---------|----------------:|-------:|
| `BeforeAnchor` | period start 2026-01-01 | 2025-12-21 – 2026-01-03 | 2026-01-08 | 2026 | 1000 |
| `PayDateOverride` | period start 2026-12-10, pay date **2027-01-04** | 2026-12-06 – 2026-12-19 | 2027-01-04 | **2027** | 1000 |
| `YearChange` | period start 2026-12-25 | 2026-12-20 – 2027-01-02 | 2027-01-07 | 2027 | 1000 |
| `Retro` | period start 2027-01-05 | 2027-01-03 – 2027-01-16 | 2027-01-21 | 2027 | 1500 |

The regulation year column applies to `cycleAssignment` `PayDate`.

Key assertions:
- `BeforeAnchor`: the period before the anchor date is resolved backwards from the anchor
- `PayDateOverride`: the invocation pay date overrides the calendar pay date
- `YearChange`: the period across the year change is paid in 2027 and ends in 2027
- All invocation period starts lie within the period: the job period is the anchored period

### Cycle by Assignment

| Job | `PayDate`: WT103 / WT104 / WT105 / WT106 / WT107 | `PeriodEnd`: WT103 / WT104 / WT105 / WT106 / WT107 |
|:----|:--------------------------------------------------|:----------------------------------------------------|
| `BeforeAnchor` | 2026 / 2026 / 0 / 1 / 26 | 2026 / 2026 / 0 / 1 / 26 |
| `PayDateOverride` | **2027 / 2027** / 0 / **1 / 27** | 2026 / 2026 / 1000 / 0 / 26 |
| `YearChange` | 2027 / 2027 / **1000** / 0 / 27 | 2027 / 2027 / 0 / 1 / 26 |
| `Retro` | 2027 / 2027 / **3000** / 0 / 27 | 2027 / 2027 / 1500 / 0 / 26 |

- `PayDate`: the December period paid on 2027-01-04 belongs to the 2027 cycle and selects
  the 2027 regulation. It becomes the first period of the 2027 cycle, which therefore has
  27 periods. Its salary is part of the 2027 year to date (`YearChange`, `Retro`)
- `PeriodEnd`: the same period ends in 2026 and stays in the 2026 cycle and regulation,
  regardless of the pay date. Both cycles have 26 periods
- `Retro` year to date: the consolidated results include the retro corrections of the
  current payrun (1500 per corrected period)

### Retro Runs of Job `Retro`

| Retro period | WT110 | WT120 (pay date) | WT121 `PayDate` | WT121 `PeriodEnd` |
|:-------------|------:|-----------------:|----------------:|------------------:|
| 2026-12-06 – 2026-12-19 | 1500 | 20270104 | 2027 | **2026** |
| 2026-12-20 – 2027-01-02 | 1500 | 20270107 | 2027 | 2027 |

The retro runs reuse the pay date of the original period job, including the pay date
override of `PayDateOverride`, and select the regulation by the cycle assignment.
The main job collects the retro delta WT111 = 2 × (1500 − 1000) = **1000**.

## Running the Test

```cmd
cd Tests\PayDate.Test
Test.pecmd

# or via Test.All:
# Test.All.pecmd includes PayDate.Test/Test.pecmd
```

## See Also

- [RetroPayMode.Test](../RetroPayMode.Test/) — retro sub-run control
- [WeekCalendar.Test](../WeekCalendar.Test/) — weekly calendar periods
