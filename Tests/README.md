# Payroll Engine Tests

Integration tests for the PayrollEngine, executed via **PayrollConsole** (`pecmd`).  
Each test builds a self-contained tenant, runs payrun job(s), and asserts expected results.

## Commands

| Command | Description |
|:--|:--|
| `Test.All.pecmd` | Runs all tests sequentially |
| `<Test>/Test.pecmd` | Runs a single test |
| `<Test>/Delete.pecmd` | Removes the test tenant |

---

## Test Types

| Type | Command | Description |
|:--|:--|:--|
| **Payrun** | `PayrunTest *.pt.json` | Executes payrun jobs and asserts wage type, collector and payrun results |
| **Case** | `CaseTest *.ct.json` | Tests case availability, build and validate lifecycles |
| **Payrun Employee** | `PayrunEmployeeTest *.et.json` | Payrun for specific employees with result assertions |
| **Payrun Employee Preview** | `PayrunEmployeePreviewTest *.et.json` | Preview mode (no persistence) for employee payruns |
| **Report** | `ReportTest *.rt.json` | Tests report build and execute output |

---

## Tests

### Aggregation.Test
**Type:** Payrun  
**Tenant:** `Aggregation.Test`  
**What it tests:** The three `PeriodAggregation` modes for case fields of type `Period`:

| Mode | Behaviour | WT | Expected |
|:--|:--|:--|:--|
| `Summary` | Sum all active values within period | 101.1 | 18 000 (5 000+6 000+7 000) |
| `Last` | Most recently created value | 101.2 | 4 000 |
| `First` | Oldest created value | 101.3 | 8 000 |

Data: 3 overlapping period values per field (Jan 4 / Jan 14 / Jan 24, Jan 2019).  
**Special flags:** none

---

### Collector.Test
**Type:** Payrun  
**Tenant:** `Collector.Test`  
**What it tests:** Core collector features across three payrun jobs:

| Collector | Feature | Config | Scenario |
|:----------|:--------|:-------|:---------|
| `GrossWage` | Multi-source accumulation | plain | WT101 (Salary) + WT102 (Bonus) both feed the same collector |
| `SocialBase` | Upper cap | `maxResult: 3000` | Jan/Feb: below cap; Mar: Salary 4000 capped to 3000 |
| `MinWageBase` | Lower floor | `minResult: 2000` | Jan: Salary 1000 floored to 2000; Feb/Mar: above floor |
| `NegatedDeduction` | Sign negation | `negated: true` | Deduction 300 stored as -300 across all three jobs |

**Special flags:** none

---

### Calendar.Test
**Type:** Payrun  
**Tenant:** `Calendar.Test`  
**What it tests:** Standard Gregorian calendar behaviour — period start/end boundaries, cycle transitions.  
**Special flags:** none

---

### Cancellation.Test
**Type:** Payrun  
**Tenant:** `Cancellation.Test`  
**What it tests:** All four `CancellationMode` values across three value types:

| Mode | Behaviour |
|:--|:--|
| `Keep` | Cancelled value is retained as-is |
| `Reset` | Cancelled value becomes `0` / `false` |
| `Invert` | Numeric sign is flipped; boolean is toggled |
| `Previous` | Falls back to the value before the cancelled entry |

Value types covered: `Integer`, `Decimal`, `Boolean`.  
**Special flags:** none

---

### Case.Test
**Type:** Case  
**Tenant:** `CaseTest`  
**What it tests:** Case lifecycle for an Employee case (`MonthlyWage`):
- **Available** – case visibility (hidden when wage ≤ 5 000)
- **Build** – field derivation (`SpecialDeduction = MonthlyWage × 0.085` when > 5 000)
- **Validate** – acceptance of valid case values
- Includes custom C# test class `EmployeeTest.cs`

**Import:** `PayrollImport Payroll.json` before case tests.  
**Special flags:** none

---

### ConsolidatedPayroll.Test
**Type:** Payrun  
**Tenant:** `Consolidated.Tenant`  
**What it tests:** Year-to-date accumulation using `GetConsolidatedWageTypeResults`:

| Period | WT 101 (current) | WT 102 (YTD prev.) | WT 103 (YTD total) |
|:--|--:|--:|--:|
| Oct 2018 | 5 000 | 0 | 5 000 |
| Nov 2018 | 5 000 | 5 000 | 10 000 |
| Dec 2018 | 5 000 | 10 000 | 15 000 |

`consolidatedPayMode = ValueChange`, 3 consecutive months.  
**Special flags:** `/testPrecisionOff` (floating-point tolerance)

---

### CountryPayroll.Test
**Type:** Payrun  
**Tenant:** `CountryPayroll.Test`  
**What it tests:** Country-specific scripting functions via a custom `FunctionRegister`. Tests that country-level C# extensions (`CountryFunction`, `CountryPayrollFunction`) are properly compiled and invoked during a payrun.  
**Special flags:** none

---

### Culture.Test
**Type:** Payrun  
**Tenant:** `Culture.Test`  
**What it tests:** Culture-sensitive payrun behaviour — number/date formatting, culture propagation into scripting functions.  
**Special flags:** `/keeptest` (tenant is retained after test for manual inspection)

---

### DerivedPayroll.Test
**Type:** Payrun  
**Tenant:** `DerivedPayroll.Test`  
**What it tests:** Two-layer regulation inheritance:

- **Root regulation** defines WT 101–105, Lookup `Factor` (A=100, B=200), Collector `AHV Base`
- **Derived regulation** overrides WT 101 (adds `Company Collector`), deactivates WT 102 (`overrideType=Inactive`), overrides Lookup key A (→1 000), adds WT 106 (`HourlyWage`)
- Asserts that base and derived values resolve correctly, including `overrideType=Inactive` producing no result

**Special flags:** none

---

### ForecastPayroll.Test
**Type:** Payrun  
**Tenant:** `ForecastPayroll`  
**What it tests:** Forecast payrun jobs — runs a payrun against a future evaluation date using case values that are not yet active (wage change effective 2022-01-01, evaluated 2020-12-28):

| Job | Period | WT 101 |
|:--|:--|--:|
| Jan 2021 (forecast) | 2021-01 | 5 000 |
| Jan 2022 (forecast) | 2022-01 | 6 000 |

Both jobs use `forecast = "Forecast2022"`.  
**Special flags:** none

---

### IncrementalPayroll.Test
**Type:** Payrun  
**Tenant:** `IncrementalPayroll.Test`  
**What it tests:** Full vs. Incremental `jobResult` modes for the same period:

| Job | Mode | WT 101 |
|:--|:--|--:|
| Full run | `Full` | 1 000 |
| Incremental run | `Incremental` | *(empty — no new changes)* |

**Special flags:** none

---

### Lookup.Test
**Type:** Payrun  
**Tenant:** `Lookup.Test`  
**What it tests:** Lookup value access — key-based lookup, range-based lookup, and edge cases (missing keys, boundary values).  
**Special flags:** `/wait` (pauses on failure for interactive debugging)

---

### LunisoralCalendar.Test
**Type:** Payrun  
**Tenant:** `LunisoralCalendar.Test`  
**What it tests:** Lunisolar calendar support — period calculation with non-Gregorian month boundaries.  
**Special flags:** none

---

### Payrun.Test
**Type:** Payrun  
**Tenant:** `Payrun.Test`  
**What it tests:** Basic payrun execution — standard wage type evaluation, result storage and assertion.  
**Special flags:** none

---

### PayrunActions.Test
**Type:** Payrun  
**Tenant:** `PayrunAction.Tenant`  
**What it tests:** No-Code action syntax for wage type value expressions across 9 wage types:

| WT | Name | Tests |
|:--|:--|:--|
| 101 | MonthlyWage | Conditional action (`? >= 5000`), custom payrun result |
| 102 | MonthlyWageConsolidated | Cycle aggregation via `^$WageType.Cycle` |
| 103 | MonthlyWageYtd | Cross-wage-type addition `^$ + ^$` |
| 104 | LookupWage | Key lookup `^#Lookup('key')` |
| 105 | RangeLookupWage | Range lookup `^#Lookup(value)` |
| 106 | MonthlyRateWage | Multi-case multiplication |
| 107 | MonthlyRateWageInvalid | Known incorrect result via runtime values (documented as limitation) |
| 108 | DuplicateMonthlyRateWage | `Duplicate()` action |
| 109 | ConditionEvaluationOrderWage | Compound boolean expression with month check |

3 payrun jobs (Oct–Dec 2025), `consolidatedPayMode = ValueChange`.  
**Special flags:** `/testPrecisionOff`, `/keeptest`

---

### PayrunEdge.Test
**Type:** Payrun  
**Tenant:** `PayrunEdge`  
**What it tests:** Date boundary and temporal edge cases across all axes that affect payrun results:

| Scenario | Job(s) | What is verified |
|:--|:--|:--|
| **Period boundary** | Jan–Mar 2024 | `BaseSalary` (CalendarPeriod) switches correctly at month boundaries |
| **Retro trigger** | Mar 2024 | Case value with `created=Mar5` invisible at `evalDate=Feb28`, visible at `evalDate=Mar28`; triggers retro sub-run for Feb; `GetWageTypeRetroResultSum` returns +1 000 |
| **Period touching** | Apr 2024 | `Supplement` (Period): value A ends `Apr1`, value B starts `Apr1` — Apr run returns value B (200) |
| **Overlapping case values** | Apr 2024 | Two `OverlapAllowance` entries for same CalendarPeriod; latest `created` (Apr 1 → 600) wins over earlier (Mar 1 → 500) |
| **Mid-period split** | Jan–Feb 2024 | `SplitBonus` (Period) starts Feb 15; Jan run returns 0, Feb run returns 300 |
| **evalDate == PeriodStart** | Jun 2024 | `evalDate=Jun1`. WageType `created=Jun1` **is** derived (`<=`). CaseValue `created=Jun1` is **not** visible (strict `<`) |
| **evalDate == PeriodEnd** | Jul 2024 | `evalDate=Jul31`; `EvaluationDate.Day=31` |
| **evalDate == CycleEnd** | Dec 2024 | `evalDate=Dec31`; `EvaluationDate.Day=31` |
| **Forecast** | Aug 2024 | `forecast="EdgeForecast"`, period ahead of evalDate; `IsForecastIndicator=1` |

**Special flags:** none

---

### PayrunEmployee.Test
**Type:** Payrun Employee  
**Tenant:** `Employee.Test`  
**What it tests:** Multi-employee payrun over 7 months (Jan–May, Dec 2019, Jan 2020) for 2 employees (`višnja.müller@foo.com`, `remo.meier@foo.com`).  
Case fields: `MonthlyWage`, `HourlyWage`, `EmploymentLevel`, `Location`, `Bonus`, `Department`, `NumberOfHours`, `BirthDate`.  
Collectors: `AHV Base`, `QST Base`, `Credit`, `Debit`.  
Verifies time-split partial salary calculations, bonus stacking, and payrun results.  
**Special flags:** `/keeptest`

---

### PayrunEmployeePreview.Test
**Type:** Payrun Employee Preview  
**Tenant:** `EmployeePreview.Test`  
**What it tests:** Same scenario as `PayrunEmployee.Test` but in preview mode (no DB persistence). Results must match identically to verify that preview calculations are consistent with committed runs.  
**Special flags:** none

---

### Report.Test
**Type:** Report  
**Tenant:** `ReportTest`  
**What it tests:** Report build and execute pipeline:
- **Build test:** `EmployeesReport` with `culture=de-CH` — asserts `EmployeeType=2` in output parameters
- **Execute test:** Validates the `Employees` DataTable (2 rows: `braunger.margarete`, `frühling.Andreas`)

Custom C# test class `EmployeeTest.cs` for extended assertions.  
**Import:** `PayrollImport Payroll.json` before report tests.  
**Special flags:** `/showall`

---

### RetroManualPayroll.Test
**Type:** Payrun  
**Tenant:** `RetroManualPayroll.Test`  
**What it tests:** Manual retro payrun jobs — explicit retro-period specification by the user, as opposed to automatic retro triggering.  
**Special flags:** none

---

### RetroPayroll.Test
**Type:** Payrun  
**Tenant:** `RetroPayroll.Test`  
**What it tests:** Automatic retro payrun — when a case value change affects a past period, the engine automatically creates retro correction jobs.  
**Special flags:** `/testPrecisionOff`

---

### TimeTracking.Test
**Type:** Payrun  
**Tenant:** `TimeTracking.Test`  
**What it tests:** Time tracking integration — reading time data within wage type scripts via `GetRate.cs`, applying hourly rates to tracked hours.  
**Special flags:** none

---

### VersionPayroll.Test
**Type:** Payrun  
**Tenant:** `VersionPayroll.Test`  
**What it tests:** Payroll versioning — multiple regulation versions coexist; the correct version is applied based on the payrun evaluation date.  
**Special flags:** none

---

### RetroPayMode.Test
**Type:** Payrun  
**Tenant:** `RetroPayMode.Test`  
**What it tests:** The effect of `retroPayMode` on whether retro sub-runs are created when prior-period case mutations are detected:

| Job | retroPayMode | Jan mutation visible | Retro sub-run created | WT102 (diff) |
|:----|:-------------|:--------------------:|:---------------------:|-------------:|
| Jan24 | ValueChange | No (created=Feb15) | No | 0 |
| Feb24 | **None** | Yes | **No — suppressed** | 0 |
| Mar24 | **ValueChange** | Yes (unprocessed) | **Yes** | 1000 |

WT103 (`IsRetroIndicator`) returns `1` inside the sub-run and `0` in main runs, confirming sub-run creation.  
**Special flags:** none  
**Has own README:** `RetroPayMode.Test/README.md`

---

### WageTracingPayroll.Test
**Type:** Payrun  
**Tenant:** `WageTracingPayroll.Test`  
**What it tests:** Wage calculation traceability via `clusterSetWageTypePeriod`. Stores one `WageTypeCustomResult` per case-value time-split per wage type.  

Scenario: 2 employees, 2 months (Jan–Feb 2025):
- **Alex Brown**: Salary 4 000 → 5 600 effective Feb 10 → prorated split in Feb
- **Sam Green**: EmploymentLevel 0.8 → 1.0 effective Feb 15 → split in Feb

| Month | Alex WT100 | Sam WT100 |
|:--|--:|--:|
| Jan 2025 | 4 000.00 | 2 880.00 |
| Feb 2025 | 5 085.71 | 3 240.00 |

Custom Results (sub-period audit trail) are not assertable via `payrollResults` — verified via REST API / Web App.  
**Special flags:** none  
**Has own README:** `WageTracingPayroll.Test/README.md`

---

### WageTypeRestart.Test
**Type:** Payrun  
**Tenant:** `WageTypeRestart.Test`  
**What it tests:** Wage type calculation restart — when a wage type triggers a restart, subsequent wage types in the run order are re-evaluated.  
**Special flags:** none

---

### WeekCalendar.Test
**Type:** Payrun  
**Tenant:** `WeekCalendar.Test`  
**What it tests:** Weekly calendar — period boundaries and payrun execution on week-based cycles instead of calendar months.  
**Special flags:** none

---

## Test Options Reference

| Option | Effect |
|:--|:--|
| `/testPrecisionOff` | Disables exact decimal matching (floating-point tolerance) |
| `/keeptest` | Tenant is not deleted after the test |
| `/wait` | Pauses on test failure (interactive debugging) |
| `/showall` | Outputs all result rows, not just failures |

---

## File Conventions

| Extension | Description |
|:--|:--|
| `*.pt.json` | Payrun test — full tenant + regulation + payrun jobs + expected results |
| `*.ct.json` | Case test — available / build / validate test cases |
| `*.et.json` | Employee payrun test — uses existing imported tenant |
| `*.rt.json` | Report test — build and execute assertions |
| `Test.pecmd` | Runs Delete + test command for this test |
| `Delete.pecmd` | Removes the test tenant from the database |
| `Import.pecmd` | Imports base payroll data before the test |
