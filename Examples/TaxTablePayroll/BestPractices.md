# Best Practices — TaxTablePayroll

Lessons learned from the TaxTablePayroll integration example.

---

## Regulation Design

**Declare the lookup schema in the regulation, fill it via import.**
The regulation defines the lookup with `values: []`. The actual data
comes from `LookupTextImport`. This keeps the regulation stable across
annual updates — only the source file changes, not the regulation itself.

**One regulation, one layer.**
All artefacts (lookup, cases, wage types, collectors, payroll, payrun)
belong to a single regulation. Multiple layers are only needed when
multiple independent regulations must be combined. The payroll engine
resolves all objects across layers transparently at runtime.

**Employee-specific parameters belong in a case.**
Tax table number and taxpayer category are employee data, not regulation
constants. Storing them in a dedicated employee case (`TaxTableSettings`)
makes them time-tracked and editable per employee without touching the
regulation.

---

## Lookup Design

**Choose `RangeMode` based on what the source publishes.**
If the authority publishes pre-calculated deduction amounts, no
`RangeMode` is needed — `GetRangeObjectLookup` returns the value
directly. Use `Threshold` or `Progressive` only when rates are published
and the engine must compute the deduction itself.

**Use a composite key to disambiguate overlapping tables.**
When a single lookup holds data for multiple tax tables, combine the
discriminating fields into one key (e.g. `"30 34"` for period type +
table number). This avoids separate lookups per table and allows one
import run to populate all variants.

**Use named columns for multi-dimensional values.**
Storing multiple values per bracket as named columns (`Col1`…`Col6`) in
a `valueObject` is more maintainable than separate lookups per column.
The column name becomes a runtime parameter, not a design-time decision.

---

## Import

**Use `/bulk` for large data sources.**
Single-record import makes one API call per value. For thousands of
records, `/bulk` writes all values in one request and is significantly
faster.

**Use `SliceSize` when the payload must be limited.**
If the backend or network imposes request size limits, specify a
`SliceSize`. `LookupTextImport` handles the `UpdateMode` sequencing
automatically: the first slice resets the lookup (`Update`), each
subsequent slice appends (`NoUpdate`). No manual orchestration is needed.

**Keep source files out of the repository.**
Tax table files are published annually by the authority and can be
several hundred kilobytes. They are input data, not regulation artefacts.
Reference the expected filename in the README and exclude the file from
version control.

**Separate the import step from the regulation import.**
`Setup.pecmd` runs both steps in sequence, but `Import.pecmd` allows
re-running only the data import (e.g. after an annual table update)
without reimporting the full regulation.

---

## Wage Type Expression

**Resolve all employee parameters before the lookup call.**
Read `TaxTableNumber` and `TaxColumn` from the case first, then
construct the lookup key and column name. This makes the expression
readable and the parameters easy to trace in test failures.

**Return a negated value for deductions.**
`GetRangeObjectLookup` returns the raw table value (positive). Negate
the return value explicitly (`return -deduction`) so the collector
semantics (`negated: true`) and the net income calculation remain
consistent and self-documenting.
