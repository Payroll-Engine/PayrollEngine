# Best Practices — MultiCountryPayroll

Lessons learned from the MultiCountryPayroll integration example.

---

## Regulation Architecture

**Extract globally shared logic into a base regulation.**
`ACME.Global` holds the elements that are identical across all countries:
the base salary calculation, the company bonus, and the collector
definitions. Country regulations contain only what differs. This avoids
duplicating and maintaining identical expressions in every country.

**Mark the base regulation as shared.**
`sharedRegulation: true` on `ACME.Global` allows all three country
payrolls to reference it without importing it into each payroll's own
tenant scope. Any change to the global logic propagates automatically to
all countries.

**Use two layers: global base at level 1, country specifics at level 2.**
The payroll engine merges layers from lowest to highest level at runtime.
Level 1 contributes the shared foundation; level 2 adds or overrides
country-specific elements. Adding a fourth country requires only a new
regulation and a new payroll — the base layer is unchanged.

**Define collectors once in the base regulation.**
`Gross Income` and `Deductions` are declared in `ACME.Global` and
inherited by all country regulations. Country wage types write into
`Deductions` by name — no country regulation needs to redeclare or
reconfigure the collectors.

---

## Case Design

**Use `valueScope: Global` only for values that are truly cross-country.**
`Salary` and `CompanyBonus Rate` carry `valueScope: Global` because they
must be the same regardless of which country payroll reads them. Setting
a salary once in the DE payroll makes it readable by the FR payroll
without a second data entry. Do not apply global scope to values that
legitimately differ per country.

**Leave country-variable fields non-global intentionally.**
`EmploymentLevel` is NOT global. A split-country employee like Sophie
Klein works 60 % in Germany and 40 % in France — two different values
for the same field. Non-global scope allows each country payroll to
maintain its own value independently. The regulation comment documents
this design decision explicitly.

**Assign employees to multiple divisions to model cross-country work.**
Sophie Klein's `divisions` list contains both `ACME.DE` and `ACME.FR`.
Division membership controls which payrolls include the employee. No
special payrun configuration is needed — each payrun processes its own
division's employees and picks up the globally scoped salary
automatically.

---

## Wage Type Design

**Reserve a consistent number range per concern across all countries.**
WT 100–199 are global income components; WT 200–299 are country
deductions. Each country regulation defines its own WT 200, 210, 220
with country-specific logic. There is no collision because each
regulation lives in its own payroll. The convention makes the structure
of any country regulation immediately readable.

**Country deduction expressions read from the collector, not from WT 100.**
All three country deductions compute against `Collector["Gross Income"]`.
If WT 110 (Company Bonus) is later renamed or replaced, no deduction
expression needs updating — the collector absorbs the change.

---

## Split-Country Employee Pattern

**Set the global salary through one country payroll only.**
Sophie's salary is imported via `ACME.Payroll.DE`. The `reason` field
documents this explicitly: *"Initial salary (global — shared with FR
payroll)"*. A clear convention on which payroll owns the canonical
salary entry prevents accidental duplicate updates.

**Provide the split employment levels in their respective payrolls.**
Sophie's DE employment level (0.6) is imported via `ACME.Payroll.DE`
with division `ACME.DE`; her FR level (0.4) via `ACME.Payroll.FR` with
division `ACME.FR`. Each value is scoped to its division — the payrun
reads the correct value automatically based on which payroll is running.

---

## Testing

**Create one test result set per employee per payroll.**
`Test.et.json` contains five result sets: Anna (DE), Pierre (FR), Lucas
(NL), Sophie (DE), Sophie (FR). Testing Sophie in both payrolls verifies
that the global salary is read correctly and that each employment level
produces the expected base salary independently.

**Validate the split-country employee as the most complex case.**
Sophie's combined results across both payrolls sum to her full salary
and bonus. Asserting both payrun results separately — and optionally
summing them — catches misconfigurations in global scope, division
assignment, and employment level values simultaneously.

---

## File Structure

**One `Payroll.json` for all regulations, payrolls and payruns.**
All four regulations and three payrolls are imported in a single file.
This ensures the shared regulation is available before the country
payrolls are created, without requiring a multi-step import sequence.

**Use `divisionName` on case value imports to scope them correctly.**
Every case value in `Payroll.Values.json` specifies `divisionName`.
For single-country employees this matches their only division; for
Sophie it selects the correct division context for each employment level.
Omitting `divisionName` would import the value at the wrong scope.
