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

## Payrun Tests

### Aggregation.Test
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

### Calendar.Test
**Tenant:** `Calendar.Test`  
**What it tests:** Standard Gregorian calendar behaviour — period start/end boundaries, cycle transitions.  
**Special flags:** none

---

### Cancellation.Test
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

### CaseScope.Test
**Tenant:** `CaseScope.Test`  
**What it tests:** National, Company and Employee case scope isolation across two payrun jobs:

| Scope | Case | Field | Value |
|:------|:-----|:------|:------|
| National | `LegalMinimum` | `MinWageRate` | 24.50 |
| Company | `CompanySettings` | `EmployerRate` | 0.05 → **0.08** (Feb) |
| Employee | `EmployeeContract` | `Salary` | 5 000 |

| Job | WT101 (floor guard) | WT102 (Salary × rate) | WT103 (Salary) |
|:----|:---:|:---:|:---:|
| Jan 2024 | 5 000 | **250** | 5 000 |
| Feb 2024 | 5 000 | **400** | 5 000 |

Key assertion: Company `EmployerRate` change propagates in Feb; National `MinWageRate` is unaffected.  
**Has own README:** `CaseScope.Test/README.md`  
**Special flags:** none

---

### Collector.Test
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

### ConsolidatedEdge.Test
**Tenant:** `ConsolidatedEdge.Test`  
**What it tests:** `NoRetro` flag on `GetConsolidatedWageTypeResults` — verifies that the flag correctly includes or excludes retro sub-run results from the consolidated prior-period view:

| WT | Name | NoRetro | Jan result in Feb query |
|---:|:-----|:-------:|------------------------:|
| 103 | `ConsolidatedWithRetro` | `false` (default) | **6 000** (retro value) |
| 104 | `ConsolidatedNoRetro` | `true` | **5 000** (original main-run value) |

Scenario: Jan baseline salary = 5 000; retro mutation to 6 000 (created Feb 15) triggers a retro sub-run for January in the Feb job.  
**Has own README:** `ConsolidatedEdge.Test/README.md`  
**Special flags:** none

---

### ConsolidatedPayroll.Test
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
**Tenant:** `CountryPayroll.Test`  
**What it tests:** Country-specific scripting functions via a custom `FunctionRegister`. Tests that country-level C# extensions (`CountryFunction`, `CountryPayrollFunction`) are properly compiled and invoked during a payrun.  
**Special flags:** none

---

### Culture.Test
**Tenant:** `Culture.Test`  
**What it tests:** Culture-sensitive payrun behaviour — number/date formatting, culture propagation into scripting functions.  
**Special flags:** `/keeptest` (tenant is retained after test for manual inspection)

---

### DerivedPayroll.Test
**Tenant:** `DerivedPayroll.Test`  
**What it tests:** Two-layer regulation inheritance:

- **Root regulation** defines WT 101–105, Lookup `Factor` (A=100, B=200), Collector `AHV Base`
- **Derived regulation** overrides WT 101 (adds `Company Collector`), deactivates WT 102 (`overrideType=Inactive`), overrides Lookup key A (→1 000), adds WT 106 (`HourlyWage`)
- Asserts that base and derived values resolve correctly, including `overrideType=Inactive` producing no result

**Special flags:** none

---

### ForecastPayroll.Test
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
**Tenant:** `IncrementalPayroll.Test`  
**What it tests:** Full vs. Incremental `jobResult` modes for the same period:

| Job | Mode | WT 101 |
|:--|:--|--:|
| Full run | `Full` | 1 000 |
| Incremental run | `Incremental` | *(empty — no new changes)* |

**Special flags:** none

---

### Lookup.Test
**Tenant:** `Lookup.Test`  
**What it tests:** Lookup value access — key-based lookup, range-based lookup, and edge cases (missing keys, boundary values).  
**Special flags:** `/wait` (pauses on failure for interactive debugging)

---

### LunisoralCalendar.Test
**Tenant:** `LunisoralCalendar.Test`  
**What it tests:** Lunisolar calendar support — period calculation with non-Gregorian month boundaries.  
**Special flags:** none

---

### MultiDivision.Test
**Tenant:** `MultiDivision.Test`  
**What it tests:** Division-scoped case value isolation — same employee assigned to two divisions (`DE`, `CH`), each with its own `Salary` (`valueScope: Division`):

| Payroll / Division | WT101 (Salary) | WT102 (Salary × 2) |
|:-------------------|---------------:|-------------------:|
| `MultiDivision.DE.Payroll` / DE | **4 000** | **8 000** |
| `MultiDivision.CH.Payroll` / CH | **6 000** | **12 000** |

Both payruns use the same regulation and run the same period (Jan 2024). The division context determines which salary is resolved.  
**Has own README:** `MultiDivision.Test/README.md`  
**Special flags:** none

---

### Payrun.Test
**Tenant:** `Payrun.Test`  
**What it tests:** Basic payrun execution — standard wage type evaluation, result storage and assertion.  
**Special flags:** none

---

### PayrunJobImport.Test
**Tenant:** `PayrunJobImport.Test`  
**What it tests:** Archive restore via the `POST /payruns/jobs/import` endpoint. Full export → delete → import → verify cycle:

1. Run 2 payrun jobs (`Import.Payrun.Jan24`, `Import.Payrun.Feb24`) for employee `anna.mueller@import.test`
2. Export payrun jobs and payroll result sets via `GET`
3. Delete all payrun jobs (simulates archiving)
4. Import via `POST /payruns/jobs/import` with a composed `PayrunJobSet[]` payload
5. Verify that both jobs are present after import

| Job | Employee | WT 1000 (BasicWage) | Collector Gross |
|:----|:---------|--------------------:|----------------:|
| Jan24 | anna.mueller@import.test | 4 000 | 4 000 |
| Feb24 | anna.mueller@import.test | 4 000 | 4 000 |

The `Import.PayrunJobSets.json` payload is composed client-side from the two exports (matching via `payrunJobName`). See the `PayrunJobSetCompose` console command.  
**Special flags:** none

---

### PayrunActions.Test
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

### PayrunTag.Test
**Tenant:** `PayrunTag.Test`  
**What it tests:** `GetWageTypeResults` with a `Tag` filter — verifies that only results stored under the queried tag are returned; results under a different or absent tag are invisible:

| WT | Name | Tag filter | Expected |
|---:|:-----|:----------:|---------:|
| 201 | `TagAlphaResult` | `Alpha` | **750** (Alpha retro sub-run result) |
| 202 | `TagBetaResult` | `Beta` | **0** (no Beta retro was ever scheduled) |

WT110 (`RetroMarker`) returns 750 inside any retro sub-run and 0 in main runs; it is the distinguishing signal queried by WT201/202.  
**Has own README:** `PayrunTag.Test/README.md`  
**Special flags:** none

---

### RetroManualPayroll.Test
**Tenant:** `RetroManualPayroll.Test`  
**What it tests:** Manual retro payrun jobs — explicit retro-period specification by the user, as opposed to automatic retro triggering.  
**Special flags:** none

---

### RetroPayMode.Test
**Tenant:** `RetroPayMode.Test`  
**What it tests:** The effect of `retroPayMode` on whether retro sub-runs are created when prior-period case mutations are detected:

| Job | retroPayMode | Jan mutation visible | Retro sub-run created | WT102 (diff) |
|:----|:-------------|:--------------------:|:---------------------:|-------------:|
| Jan24 | ValueChange | No (created=Feb15) | No | 0 |
| Feb24 | **None** | Yes | **No — suppressed** | 0 |
| Mar24 | **ValueChange** | Yes (unprocessed) | **Yes** | 1000 |

WT103 (`IsRetroIndicator`) returns `1` inside the sub-run and `0` in main runs, confirming sub-run creation.  
**Has own README:** `RetroPayMode.Test/README.md`  
**Special flags:** none

---

### RetroPayroll.Test
**Tenant:** `RetroPayroll.Test`  
**What it tests:** Automatic retro payrun — when a case value change affects a past period, the engine automatically creates retro correction jobs.  
**Special flags:** `/testPrecisionOff`

---

### TimeTracking.Test
**Tenant:** `TimeTracking.Test`  
**What it tests:** Time tracking integration — reading time data within wage type scripts via `GetRate.cs`, applying hourly rates to tracked hours.  
**Special flags:** none

---

### Timeless.Test
**Tenant:** `Timeless.Test`  
**What it tests:** Regression for a `NullReferenceException` in the timeless case value codepath. Verifies that `Timeless` fields are readable across all periods, including when an optional timeless field has not yet been set:

| Job | `BirthDate` | `TaxCode` | WT101 (AgeAllowance) | WT102 (TaxAmount) |
|:----|:-----------:|:---------:|:--------------------:|:-----------------:|
| Jan 2024 | set | **absent** | 450 | **0** (null-safe) |
| Feb 2024 | stable | "A" | 450 | 300 (× 5 %) |
| Mar 2024 | stable | **"B"** | 450 | 480 (× 8 %) |

Both fields use `timeType: Timeless` (no `start`/`end`). `TaxCode` changes between jobs via `created` ordering.  
**Has own README:** `Timeless.Test/README.md`  
**Special flags:** none

---

### VersionEdge.Test
**Tenant:** `VersionEdge.Test`  
**What it tests:** Regulation `validFrom` boundary behaviour — the two cases not covered by `VersionPayroll.Test`:

| Job | `evaluationDate` | `validFrom` V2/V3 | Active version | WT101 |
|:----|:----------------|:-----------------|:--------------:|------:|
| Jan 2024 | 2024-01-28 | V2: Feb 1 | **V1** | 1 000 |
| Feb 2024 | **2024-02-01** | V2: **Feb 1** | **V2** (same-day `<=`) | 2 000 |
| Mar 2024 | **2024-02-28** | V3: Mar 1 | **V2** (V3 future) | 2 000 |

**Has own README:** `VersionEdge.Test/README.md`  
**Special flags:** none

---

### VersionPayroll.Test
**Tenant:** `VersionPayroll.Test`  
**What it tests:** Payroll versioning — multiple regulation versions coexist; the correct version is applied based on the payrun evaluation date.  
**Special flags:** none

---

### WageTracingPayroll.Test
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
**Has own README:** `WageTracingPayroll.Test/README.md`  
**Special flags:** none

---

### WageTypeRestart.Test
**Tenant:** `WageTypeRestart.Test`  
**What it tests:** Wage type calculation restart — when a wage type triggers a restart, subsequent wage types in the run order are re-evaluated.  
**Special flags:** none

---

### WeekCalendar.Test
**Tenant:** `WeekCalendar.Test`  
**What it tests:** Weekly calendar — period boundaries and payrun execution on week-based cycles instead of calendar months.  
**Special flags:** none

---

## Case Tests

### Case.Test
**Tenant:** `CaseTest`  
**What it tests:** Case lifecycle for an Employee case (`MonthlyWage`):
- **Available** – case visibility (hidden when wage ≤ 5 000)
- **Build** – field derivation (`SpecialDeduction = MonthlyWage × 0.085` when > 5 000)
- **Validate** – acceptance of valid case values
- Includes custom C# test class `EmployeeTest.cs`

**Import:** `PayrollImport Payroll.json` before case tests.  
**Special flags:** none

---

## Payrun Employee Tests

### PayrunEmployee.Test
**Tenant:** `Employee.Test`  
**What it tests:** Multi-employee payrun over 7 months (Jan–May, Dec 2019, Jan 2020) for 2 employees (`višnja.müller@foo.com`, `remo.meier@foo.com`).  
Case fields: `MonthlyWage`, `HourlyWage`, `EmploymentLevel`, `Location`, `Bonus`, `Department`, `NumberOfHours`, `BirthDate`.  
Collectors: `AHV Base`, `QST Base`, `Credit`, `Debit`.  
Verifies time-split partial salary calculations, bonus stacking, and payrun results.  
**Special flags:** `/keeptest`

---

## Payrun Employee Preview Tests

### PayrunEmployeePreview.Test
**Tenant:** `EmployeePreview.Test`  
**What it tests:** Same scenario as `PayrunEmployee.Test` but in preview mode (no DB persistence). Results must match identically to verify that preview calculations are consistent with committed runs.  
**Special flags:** none

---

## Report Tests

### Report.Test
**Tenant:** `ReportTest`  
**What it tests:** Report build and execute pipeline:
- **Build test:** `EmployeesReport` with `culture=de-CH` — asserts `EmployeeType=2` in output parameters
- **Execute test:** Validates the `Employees` DataTable (2 rows: `braunger.margarete`, `frühling.Andreas`)

Custom C# test class `EmployeeTest.cs` for extended assertions.  
**Import:** `PayrollImport Payroll.json` before report tests.  
**Special flags:** `/showall`

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
