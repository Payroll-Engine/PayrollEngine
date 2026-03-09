# Best Practices — GlobalPayroll

Lessons learned from the GlobalPayroll integration example.

---

## Case Design

**Match case type to scope.**
Use `National` for legislated rates that apply to all employees (e.g.
social security), `Company` for employer-level settings (e.g. health
insurance), and `Employee` for per-employee data (salary, employment
level, birth date, bonus). This makes each value editable at the right
level without duplicating it across employees.

**Use `Timeless` for data that never changes.**
`BirthDate` does not vary over time. Declaring it `Timeless` avoids
unnecessary period complexity and makes the intent explicit.

**Use `Moment` for one-time events.**
A performance bonus is recognised in exactly one pay period. `Moment`
time type expresses this directly — no workaround via period start/end
dates is needed.

**Add `reason` to every case change.**
Every case value import in `Payroll.Values.json` carries a `reason`
field. This populates the audit trail and makes historical changes
traceable in the web application.

---

## Wage Type Design

**Use wage type numbers to control processing order.**
The payrun processes wage types in ascending numeric order. Gross wage
types (100–120) must be numbered lower than deduction types (200–220)
so that `Collector["Gross Income"]` is fully accumulated before any
deduction expression reads it.

**Read from the collector, not from individual wage types.**
Deduction expressions (`Income Tax`, `Social Security`, `Health
Insurance`) all read from `Collector["Gross Income"]`. This means a
new gross wage type only needs to be added to the collector — no
deduction expression needs to change.

**Keep conditional logic inside the expression.**
The Senior Supplement checks `BirthDate` and returns `0M` when the
condition is not met, rather than using an availability expression to
suppress the wage type entirely. This keeps the result visible in the
payslip (as a zero line) and makes testing straightforward.

**Guard against null case values explicitly.**
`PerformanceBonus` uses `bonus.HasValue ? (decimal)bonus : 0M`. A
missing case value is a valid state (no bonus this period), not an
error. Expressions that do not guard against null will throw at runtime.

---

## Lookup Design

**Use `GetRangeLookup` when the lookup returns a rate to apply.**
`IncomeTax` stores bracket rates (e.g. `0.25`). The expression
multiplies the returned rate by the gross income. This is the plain
range pattern — no `RangeMode` needed because the lookup returns the
rate for the matching bracket directly.

**Validate the lookup result before use.**
The Income Tax expression checks `rate != null` before multiplying.
An income below the first bracket boundary returns null, not zero.
Unguarded null multiplication causes a runtime error.

---

## File Structure

**Split regulation, values and jobs into separate files.**
`Payroll.json` imports the regulation and payroll structure.
`Payroll.Values.json` imports employee case values.
`Payroll.Jobs.json` imports and executes payrun jobs.
Each file can be re-run independently — useful when updating salary
data or adding payrun periods without reimporting the full regulation.

**Use `updateMode: NoUpdate` in secondary import files.**
`Payroll.Values.json` and `Payroll.Jobs.json` set `updateMode:
NoUpdate` on tenant and payroll. This prevents accidental overwrites
when only the case values or job invocations need to be refreshed.

---

## Testing

**Make tests self-contained.**
`Test.et.json` includes both the case value setup and the expected
results in a single file. The test can be run on a clean tenant without
depending on a prior import step, which makes it reliable in CI.

**Test both employees with complementary scenarios.**
Sarah Chen (full-time, no senior supplement, with bonus) and Carlos
Rodriguez (part-time, senior supplement, no bonus) together cover every
conditional branch in the regulation. A result that is zero for one
employee is non-zero for the other, so no branch goes untested.

**Assert collector results in addition to wage type results.**
The test file validates both `wageTypeResults` and `collectorResults`.
Collector assertions catch errors in aggregation logic that individual
wage type assertions would miss.

---

## Setup Orchestration

**Use `ChangePassword` in Setup.pecmd for demo environments.**
The admin password is set as a setup step, not hardcoded in the
regulation file. This keeps credentials out of the regulation artefact
and makes them easy to change per environment.

**Set `StartupPayroll` and `StartupPage` on the admin user.**
The `attributes` on the user object configure where the web application
opens after login. For a demo or example, pointing directly to the
regulation page saves manual navigation.
