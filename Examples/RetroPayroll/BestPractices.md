# Best Practices — RetroPayroll

Lessons learned from the RetroPayroll integration example.

---

## Cluster Design

**Use two cluster sets to separate normal and retro execution.**
The payrun uses `clusterSetWageType: Legal` for normal runs and
`clusterSetWageTypeRetro: Retro`. Base and deduction wage types carry
both `Legal` and `Retro` clusters — they run in both contexts. Delta
wage types carry only `Legal` — they run once in the current period,
never inside a retro recalculation.

**Never place delta wage types in the Retro cluster.**
A delta WT calls `GetWageTypeRetroResultSum()`, which aggregates
corrections across all retro periods. If it were also in the `Retro`
cluster, the engine would re-execute it inside each retro period,
producing intermediate partial totals instead of the final accumulated
diff. `Legal`-only on delta WTs is non-negotiable.

**Number delta wage types adjacent to their source.**
WT 102 is the delta for WT 100; WT 112 for WT 110; WT 202 for WT 200;
WT 212 for WT 210. The adjacent numbering convention makes the
relationship immediately visible in reports, payslips, and test files
without requiring a lookup table.

---

## Wage Type Expressions in Retro Context

**Deduction expressions must reference wage type results, not the collector.**
WT 200 (Income Tax) uses `WageType[100] + WageType[110]` instead of
`Collector["Gross Income"]`. In a retro run the collector is not
accumulated the same way as in a normal run. Referencing individual
wage type results is reliable in both contexts.

**Guard against null for Moment-type case values.**
WT 110 (Bonus) reads `CaseValue["Bonus"]`. In periods where no bonus was
entered the value is null. The expression must handle this: returning
`0M` for null prevents a runtime error and allows the retro engine to
store a clean zero-result for the period.

---

## Retro Triggering

**`storeEmptyResults: true` is required on all baseline payrun jobs.**
`GetWageTypeRetroResultSum()` diffs the new retro result against the
previously stored value. If the baseline run did not store results, the
"old value" is treated as zero and the delta equals the full recalculated
amount — which is wrong for any period that was already paid. Every
payrun job that precedes a potential retro run must store its results.

**`Moment` time type is the correct model for late-entered one-time payments.**
Ben's bonus was entered in March but belongs to January (bonus date
2024-01-15). `Moment` places it in the period containing that date
automatically. Using `CalendarPeriod` would have required the user to
enter the bonus in the correct historical period manually — and would not
have triggered a retro run at all if January was already closed.

**Retro is triggered by evaluation date, not entry date.**
A case value change is visible in a payrun only if its `created` (or
entry) date is ≤ the payrun's `evaluationDate`. Ben's bonus (created
2024-03-08) is invisible to the January run (evaluationDate 2024-01-31)
and the February run (2024-02-29), but visible to the March run
(2024-03-31). Modelling this correctly in test data is essential for
testing the "not yet visible" baseline periods.

---

## Cascading Corrections

**The engine always diffs against the most recently stored value.**
Event C (April) re-corrects February, which Event A (March) had already
corrected. The stored February result at the time of the April run
already reflects the Event A correction (salary = 5 800, level = 1.0).
The April retro run recalculates against that, producing the correct
incremental delta. No special handling is needed — the mechanism works
the same for first and subsequent corrections.

**Negative deltas are valid and expected for overpayment corrections.**
Event C reduces Emma's employment level retroactively, making previously
paid amounts too high. The delta wage types (102, 202, 212) carry
negative values in the April run. Test assertions must include these
explicitly — a zero-only expectation on delta WTs would miss the
overpayment recovery.

---

## Testing

**Use a single `.pt.json` file for the entire retro scenario.**
`Payroll.pt.json` is a self-contained payroll test that includes the
tenant, regulation, all case value changes with their entry dates, all
payrun job invocations, and all expected results — including retro period
results. This makes the full scenario reproducible with a single command
and eliminates any dependency on prior import state.

**Assert retro period results separately from the current period.**
In `Test.et.json`, each retro recalculation appears as a separate result
set with `retroPeriodStart`. These assert the values the engine stored
for the historical period after re-running it. Asserting only the current
period would leave the retro recalculation logic untested.

**Test that unaffected employees produce zero deltas.**
Ben's April run has zero on all delta WTs (102, 112, 202, 212). Including
these explicit zero assertions confirms that the retro engine correctly
scoped the corrections to Emma only and did not bleed into unrelated
employees.

**Use `/testPrecisionOff` when fractional rounding is not the focus.**
`Test.pecmd` passes `/testPrecisionOff` to `PayrunTest`. For a scenario
focused on retro triggering and delta computation, fractional cent
differences are noise. Add precision assertions only when the regulation
explicitly tests rounding behaviour.
