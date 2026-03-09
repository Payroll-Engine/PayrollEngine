# MinWagePayroll — Best Practices

## Single-Record Year Lookup

Store annually versioned rates in a single-record lookup keyed by year. One
entry per year — no regulation change required when the statutory rate is updated.

```yaml
lookups:
- name: MinimumWage
  values:
  - key: "2026"
    value: "15.00"
  - key: "2027"
    value: "15.50"    # add annually, regulation unchanged
```

Access the current year's rate using the built-in `PeriodStartYear` integer:

```yaml
^#MinimumWage(PeriodStartYear)
```

`PeriodStartYear` is an integer; the engine converts it to a string key for
the lookup query. Use a plain `value` string — `valueObject` with field-name
access works in C# expressions but is not supported in No-Code action syntax.

---

## Intermediate Wage Types Without Collectors

Intermediate values needed only as inputs to subsequent wage types should not
be assigned to collectors. Assigning them would double-count the amount in
the collector total.

```yaml
- wageTypeNumber: 110
  name: MinWageBase
  valueActions:
  - ^^HoursWorked * ^#MinimumWage(PeriodStartYear, 'HourlyRate')
  # no collectors — intermediate reference value only
  clusters:
  - Legal
```

The value is still stored as a wage type result and accessible via `^$MinWageBase`
within the same payrun, as well as queryable via the API for audit purposes.

---

## Condition Guard for Conditional Top-Up

The same `? condition / value` two-action pattern as in `PartTimePayroll` and
`ForecastPayroll`:

```yaml
- wageTypeNumber: 120
  name: MinWageTopUp
  valueActions:
  - '? ^$MinWageBase > ^$BasePay'   # guard: skip if already compliant
  - ^$MinWageBase - ^$BasePay       # value: the shortfall
  collectors:
  - GrossIncome
```

When the guard fails the wage type produces no result. With `storeEmptyResults: true`
on the payrun job the engine stores `0` explicitly — making it queryable as a
compliance flag without requiring a special report.

---

## Wage Type Ordering and `^$` Dependencies

Wage types are processed in ascending numerical order. `^$WageTypeName` reads the
result already computed in the current payrun — so the referenced wage type must
have a lower number.

| WT # | Name | Depends on |
|---|---|---|
| 100 | BasePay | — (case values only) |
| 110 | MinWageBase | — (lookup + case values only) |
| 120 | MinWageTopUp | `^$BasePay` (100), `^$MinWageBase` (110) |

Always assign numbers so that dependencies flow strictly upward.

---

## `storeEmptyResults` as Compliance Signal

```yaml
payrunJobInvocations:
- name: FairPayPayrun.Jan26
  ...
  storeEmptyResults: true
```

Without this flag, compliant employees produce no WT 120 result at all.
With it, a `0` result is stored for every employee in every period — making
a simple filter on `wageTypeNumber = 120 AND value > 0` a complete compliance
query across all employees and periods.

---

## Lookup Versioning Without Regulation Updates

Adding a new year to the lookup requires only an import of a small YAML file
containing the new entry. The regulation itself does not need a new version,
and no existing payrun results are affected. This is the recommended pattern
for any annually-changing statutory value (minimum wage, tax thresholds, etc.).

---

## Naming Conventions

- PascalCase for all case and wage type names (`HoursWorked`, `MinWageBase`)
- Lookup field names quoted in single quotes: `'HourlyRate'`
- `M` suffix on decimal literals when needed (`0M`, `300M` in Range actions)
- `^$` names must be space-free — hence `MinWageBase` not `Min Wage Base`
