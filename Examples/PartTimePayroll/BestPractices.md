# Best Practices — PartTimePayroll

Lessons learned from the PartTimePayroll integration example.

---

## No-Code Actions in Wage Types

**WageType supports two action events: `valueActions` and `resultActions`.**
`valueActions` computes the wage type result and is the No-Code equivalent of
`valueExpression`. `resultActions` writes additional custom results. There is no
available action event on wage types — availability logic must be expressed as
conditions inside `valueActions`.

**Integrated scripting functions can be called directly from actions.**
Functions like `GetWageTypeRetroResultSum()` are available in `valueActions` without
requiring a C# `valueExpression`. This makes delta wage types fully No-Code:
```
GetWageTypeRetroResultSum(100)
```

**Use sequential condition actions to guard wage type execution.**
WT 120 uses two condition lines before the calculation:
```
? ^^EmploymentLevel >= 1.0
? ^^OvertimeHours.HasValue
^^OvertimeHours * (^^Salary / 160M) * 1.25M
```
If either `?` condition evaluates to false, the action chain stops and the wage type
produces no result.

**Numeric literals must use the `M` suffix for decimal types.**
The action compiler generates C# code. Integer and floating-point literals without a
suffix are typed as `int` or `double`. Division and multiplication against a `decimal`
case value requires explicit `M` suffix: `160M`, `1.25M`.

**`^$<n>` for wage type references — name must be space-free.**
`^$BaseSalary` reads the wage type result already computed in the current payrun period
(Memory). Names referenced via `^$` or `^&` must not contain spaces — use PascalCase.

**`^$<n>.Cycle` is NOT equivalent to `GetWageTypeRetroResultSum()`.**
`.Cycle` accumulates ALL previous payrun results within the calendar cycle — including
normal runs. `GetWageTypeRetroResultSum()` returns only results from retro-period
recalculations. Always use `GetWageTypeRetroResultSum()` for delta wage types.

---

## Time Types

**Use `Moment` only for genuinely one-time values (e.g. a performance bonus).**
`Moment` is designed for a single occurrence with a specific date. If a value can
recur or change across periods — such as overtime hours — use `CalendarPeriod` or
`Period` instead. `Moment` values are not reliably resolvable via `^^` in payrun
expressions when multiple entries exist.

**For `CalendarPeriod` case values, set `end` to the last day of the period.**
Leaving `end` open means the value remains valid into subsequent periods. For
period-specific values like overtime hours, always set an explicit `end`
(e.g. `2025-02-28` for February). Setting `end` to the first day of the next
period (e.g. `2025-03-01`) causes a pro-rata bleed into that period.
Open-ended `end` is correct for persistent values like Salary or EmploymentLevel.

---

## Case Availability vs. Wage Type Guards

**`availableActions` on a case controls data-entry visibility — not payrun execution.**
`OvertimeHours.availableActions: ["? ^^EmploymentLevel >= 1.0"]` hides the case from HR
when the employee is part-time. It does not prevent the wage type from running if a value
already exists in the database from an earlier full-time period. The wage type condition
`? ^^EmploymentLevel >= 1.0` is the payrun-level guard and must exist independently.

Both guards serve different purposes and must both be present:
- Case `availableActions` — prevents bad data entry
- WT `valueActions` condition — ensures correct payrun calculation regardless of history

---

## Case Build Actions

**Use `buildActions` for input sanitization, not validation.**
`Range(^:EmploymentLevel, 0.1, 1.0)` corrects the value silently before saving.
This is appropriate for known-bounded numeric fields where the user's intent is clear.
Use `validateActions` (with `?` conditions and issue reporting) when silent correction
is wrong and the user must fix the input manually.

---

## Retro and Cluster Design

The retro cluster design follows the same rules as NovaTechRetro:
- Base WTs (100, 120, 200, 210): `Legal` and `Retro` — re-executed in retro runs.
- Delta WTs (102, 202, 212): `Legal` only — run once in the current period via
  `GetWageTypeRetroResultSum()`, never inside a retro recalculation.
- `storeEmptyResults: true` on all jobs that precede a potential retro run.

**Negative deltas are expected for overpayment corrections.**
When a level is reduced retroactively, previously paid amounts were too high.
`GetWageTypeRetroResultSum()` on delta WTs naturally produces a negative accumulated
diff. Test assertions must include these explicitly.

**Assert that unaffected employees produce zero deltas.**
Mark's March run has zero on all delta WTs. Including explicit zero assertions
confirms the retro engine scoped the correction to Anna only.
