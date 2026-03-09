# PayrollEngine — Best Practices

Derived from integration examples:
[ActionPayroll](ActionPayroll) · [ForecastPayroll](ForecastPayroll) · [GlobalPayroll](GlobalPayroll) · [MinWagePayroll](MinWagePayroll) · [MultiCountryPayroll](MultiCountryPayroll) · [PartTimePayroll](PartTimePayroll) · [RetroPayroll](RetroPayroll) · [TaxTablePayroll](TaxTablePayroll)

---

## Regulation Design

### Regulations carry rules, not data

A regulation describes *how* payroll is calculated — it does not contain
the values it operates on. Rates, tax tables, and employee parameters are
data. They belong in cases and lookups, populated at runtime or via
import. A regulation that embeds hardcoded values must be changed every
time those values change; a regulation that reads from cases and lookups
stays stable for years.

**In practice:** declare lookups with `values: []` and fill them via
`LookupTextImport`. Store employee parameters (tax table number, employment
level, birth date) as case fields. The regulation survives an annual
table update or a salary change without modification.

### Structure follows separation of concerns

A payroll regulation grows over time. The structure chosen at the start
determines how much effort future changes require. Elements that belong
together should be grouped; elements that could change independently
should be separated.

**In practice:** split import files by concern — regulation structure,
case values, payrun jobs — so each can be refreshed without touching the
others. In multi-country setups, extract shared logic into a base
regulation and let country layers add only what differs. When retro
corrections are needed, separate the wage types that recalculate from
those that collect the diff — mixing them produces wrong results.

---

## Data Modeling

### Scope data at the right level

Every value in the system has a natural scope: some are legislated for
everyone, some apply per employer, some vary per employee. Capturing a
value at the wrong level either forces duplication or prevents legitimate
variation.

**In practice:** use `National` cases for statutory rates, `Company`
cases for employer policy, `Employee` cases for individual data.
For multi-country payrolls, `valueScope: Global` allows one canonical
salary entry to be shared across all countries — while employment level
stays per-division because it legitimately differs per country contract.

### Lookups store regulation data, cases store operational data

Lookups and cases serve different purposes. Lookups contain stable regulation
data — tax tables, statutory rates, reference values that are defined by law
or policy and change infrequently. Cases contain operational data — values
entered by HR for specific employees or the company at a specific point in time.

**In practice:** use lookups for reference tables populated via `LookupTextImport`.
Use Company cases for annually-updated statutory values (e.g. minimum wage rate)
that HR enters once per year. Do not force lookups where a Company case is the
better semantic fit. Note that numeric arguments to `^#` are always routed
through the range-lookup path — a plain string key is unreachable for
`int`-typed values like `PeriodStartYear` in No-Code actions.

### Time is a first-class dimension

Payroll data is always anchored in time. The same salary may apply
differently in January than in March; a bonus entered in March may
belong to January; a rate change effective from February affects all
subsequent periods. Ignoring the temporal model leads to corrections
that are either missed or applied to the wrong period.

**In practice:** choose the time type that matches the nature of each
value — `Timeless` for permanent attributes, `Period` for open-ended
values, `CalendarPeriod` for month-bound values, `Moment` for one-time
events on a specific date. In retro scenarios, ensure baseline results
are stored so that corrections can be computed as deltas against what
was actually paid.

---

## Wage Type Design

### Number wage types in calculation order

A payrun processes wage types in ascending numeric order. Every expression
that reads a previously computed result via `WageType[n]` or `^$Name`
depends on that wage type having already run.

**In practice:** assign numbers so that gross income components (100–199)
always precede deductions (200–299). Reserve a consistent number range
per concern across the entire regulation — the structure becomes
self-documenting and prevents ordering bugs as the regulation grows.

### Intermediate wage types do not belong to a collector

Not every wage type represents a payable amount. Reference values used
only as inputs to subsequent wage types — a minimum wage base, a
pro-rata denominator, a threshold — should carry no collector assignment.

**In practice:** omit the `collectors` list on intermediate wage types.
The engine still stores the result and makes it accessible via `^$Name`
within the same payrun, and queryable via the API for audit purposes.
Adding it to a collector would double-count the amount in the collector
total and distort reporting.

### Use condition guards to suppress zero results cleanly

Many wage types are only relevant in certain situations — a top-up only
when pay is below a threshold, a bonus only when a value is present, an
adjustment only in specific periods. Omitting a guard produces a zero
result that pollutes reporting; using a hard-coded condition in a
`valueExpression` requires Low-Code.

**In practice:** place `? <condition>` as the first action in a
`valueActions` list. If the condition is false the engine skips all
subsequent actions and produces no result. Combine with
`storeEmptyResults: true` on the payrun job when a zero must be stored
explicitly for compliance queries — any non-zero result then directly
identifies an affected employee.

### Guard against null for optional case values

A case value that has not been entered for the current period is null,
not zero. An expression that reads a null value without a guard throws
at runtime.

**In practice:** check `HasValue` before using any case value that may
be absent in normal operation — one-time bonuses, optional supplements,
Moment-type entries. Return an explicit `0M` when the value is absent.
This makes the intent visible in the payslip (zero line), keeps the
result set complete, and prevents runtime errors during periods when the
value is legitimately not set.

---

## Retro & Corrections

### Delta wage types run in the current period only — never in retro recalculations

Retro scenarios require two distinct wage type groups: base wage types
that are re-executed for each historical period, and delta wage types
that collect the accumulated correction and run exactly once in the
current payrun period.

**In practice:** assign base wage types to both `Legal` and `Retro`
clusters. Assign delta wage types (`GetWageTypeRetroResultSum()`) to
`Legal` only. If a delta wage type were placed in the `Retro` cluster,
the engine would re-execute it inside each historical period and produce
partial intermediate totals instead of the final accumulated correction.
Number delta wage types adjacent to their source (102 for 100, 202 for
200) so the relationship is visible in payslips and reports without a
lookup table.

### Store baseline results on every payrun that may be followed by a retro correction

Retro corrections are computed as the difference between the newly
recalculated historical result and the value previously stored for that
period. If no result was stored, the engine treats the prior value as
zero and the correction equals the full recalculated amount, regardless
of what was originally paid.

**In practice:** set `storeEmptyResults: true` on all payrun jobs in a
regulation that uses retro recalculation. This applies to baseline
periods even when no correction is expected yet — a retro trigger can
arrive for any past period. The same flag makes condition-guarded wage
types (compliance top-ups, optional supplements) queryable across all
employees as explicit zeros, enabling simple filter queries without
special report logic.

---

## Forecast

### Forecast payruns isolate what-if scenarios from production data

Forecast payruns share the regulation with production but operate on
forecast-tagged case data. Multiple named scenarios can run in parallel
over the same periods without affecting statutory results.

**In practice:** tag case changes with `forecast: "ScenarioName"` at the
**case change level** (the outer `CaseChangeSetup` object, not inside
`case:`). The `^^` operator automatically resolves the forecast-scoped
value as an override inside the forecast payrun — no script changes
required. Use `storeEmptyResults: true` to produce complete result sets
across all employees for comparison. Name scenarios clearly
(`SalaryIncrease2026`, `BonusScenario2026`) so results remain
unambiguous when queried across multiple scenarios.

---

## Scripting

### Separate case input validation from payrun calculation logic

Custom Actions and Expression scripts serve different execution contexts.
Custom Actions run during case input in the UI and are designed for
immediate user feedback — issues, localized messages, input guards.
Expression scripts with Extension Methods run during the payrun on the
server and have access to calculation APIs (`AddRetroJob`,
`GetPeriodWageTypeResults`, `GetLookup`) that are not available in the
case context.

Mixing the two concerns in one script produces either dead code
(payrun APIs in a Case Action) or missing feedback (UI-relevant checks
hidden inside a wage type expression).

**In practice:** use `functionTypes: ["CaseBuild"]` or
`["CaseValidate"]` for Custom Actions that guard data entry — input
ranges, format checks, period restrictions. Use `valueExpression` with
Extension Methods for payrun logic that queries results, triggers retro
runs, or performs multi-step calculations. Both layers can coexist for
the same business rule: a `CaseBuild` Action prevents invalid input
upfront; the `WageTypeValue` Expression handles the calculation
consequence at payrun time.

**Extension Method scope:** define Extension Methods on the highest
base class that provides all required APIs. `PayrunFunction` covers
both `WageTypeValue` and `CollectorEnd` contexts, allowing shared
calculation helpers (e.g. a BBG-remainder check) to be registered once
with multiple `functionTypes` and reused across wage types and
collectors without duplication.

**No-Code action syntax vs. C# API:** No-Code actions use a concise
domain syntax (`AddRetroJob`, `PreviousCyclePeriod`) that is not
available in C# script context. The equivalent C# API methods (e.g.
`ScheduleRetroPayrun(DateTime)`) are regular instance methods on the
function class and can be called directly from extension methods.
Always look up the C# API counterpart when porting No-Code action logic
into a Low-Code extension method.

**Retro scheduling in Exchange imports:** `ScheduleRetroPayrun()` must
not be called during an Exchange import payrun invocation. The scheduled
job cannot start while the current import job is still running, causing
a deadlock. In Exchange test imports, retro runs are always driven by
`retroJobs` in the YAML. `ScheduleRetroPayrun()` is for production
payrun jobs only. Keep the retro-trigger logic separate from the
calculation logic: extension methods return pure values or booleans;
the production `valueExpression` calls `ScheduleRetroPayrun()` directly
with an `!IsRetroPayrun` guard.

---

## Testing

### Design for verifiability

A payroll regulation that cannot be tested reliably is a liability.
The expected result of every calculation should be derivable from the
inputs, and the test setup should be self-contained enough to run
independently of environment state.

**In practice:** design employee scenarios in complementary pairs — one
triggers a condition, the other does not — so every branch is exercised.
Assert collector totals alongside individual wage type results. For retro
scenarios, assert the historical recalculated values explicitly, not just
the current period. A test that only checks happy-path results leaves the
most complex cases untested.
