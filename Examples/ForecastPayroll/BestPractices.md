# ForecastPayroll — Best Practices

## Forecast Data Isolation

Forecast case data is tagged at the case change level, not the regulation level.
The `forecast` field on a case entry makes that value visible **only** to payrun
jobs carrying the same forecast name. The production run ignores it entirely.

```yaml
case:
  caseName: Salary
  forecast: SalaryIncrease2026        # invisible to production runs
  values:
  - caseFieldName: Salary
    value: "6000"
    start: 2026-01-01T00:00:00Z
```

The matching forecast payrun job activates the scenario by name:

```yaml
- name: PlanSoftPayrun.SalaryIncrease.Jan26
  jobStatus: Forecast
  forecast: SalaryIncrease2026        # activates forecast-tagged case data
  periodStart: 2026-01-01T00:00:00Z
```

---

## `^^` Resolves Forecast-Scoped Values

Inside a forecast payrun, `^^CaseField` reads the forecast-tagged value first.
If a forecast value exists for the active scenario it takes precedence over the
production value. No regulation change is required.

> **Confirmed by test:** The engine correctly applies forecast-scoped case data
> as an override. `SalaryIncrease2026` saw salary 6 000 while the parallel
> `BonusScenario2026` job in the same period still resolved salary as 5 000.

| Context | `^^Salary` resolves to |
|---|---|
| Production run | 5 000 (production case value) |
| Forecast `SalaryIncrease2026` | 6 000 (forecast case value overrides) |
| Forecast `BonusScenario2026` | 5 000 (no forecast salary → falls back to production) |

---

## Condition Guard on Optional Wage Types

Use the two-action `? condition / value` pattern for wage types that are only
relevant in certain scenarios:

```yaml
valueActions:
- '? ^^PlannedBonus > 0'    # guard: stop if no bonus for this period
- ^^PlannedBonus             # value: use the bonus amount
```

`CalendarPeriod` fields with no value entered return `0`, so this guard reliably
suppresses the wage type in production runs and in scenarios where the field is
not part of the forecast data.

---

## `^$` for Cross-Wage-Type References

Deduction and net wage types must reference already-computed values from the
same payrun period. Use `^$WageTypeName` (space-free name) — not `^^` (case value):

```yaml
valueActions:
- (^$BaseSalary + ^$PlannedBonus) * 0.20    # IncomeTax
```

This is identical in both production and forecast runs — no special handling needed.

---

## Parallel Scenarios

Any number of forecast scenarios can coexist for the same payroll and period.
Each scenario is a separate set of payrun jobs identified by the forecast name.
Results are stored independently and can be queried side by side via
`GetPeriodWageTypeResults` filtered by forecast name.

Naming convention for forecast job invocations:

```
<PayrunName>.<ScenarioName>.<Period>
```

Example: `PlanSoftPayrun.SalaryIncrease.Jan26`, `PlanSoftPayrun.BonusScenario.Jan26`

---

## storeEmptyResults for Guarded Wage Types

Set `storeEmptyResults: true` on forecast job invocations so that guarded wage
types (like `PlannedBonus` in the `SalaryIncrease2026` scenario) store a `0`
result. This makes the result set complete and consistent across all scenarios,
simplifying downstream comparison queries.

---

## Naming Conventions

- PascalCase for all case names, field names, and wage type names
  (`PlannedBonus` not `Planned Bonus` — spaces break `^$` and No-Code name references)
- `M` suffix for decimal literals in actions (`0.20M`, `500M`) — not needed here
  since all multipliers are already computed by `^^` and `^$` references
- Quote `?` actions in YAML: `'? ^^PlannedBonus > 0'`
