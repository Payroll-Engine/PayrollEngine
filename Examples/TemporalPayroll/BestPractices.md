# TemporalPayroll — Best Practices

## The Two Time Axes Are Independent

`periodStart` and `evaluationDate` control different aspects of case
value resolution and can be set independently:

| Parameter | Controls |
|---|---|
| `periodStart` (valueDate) | Which entry is *active* — selects entries where `Start ≤ periodStart < End` |
| `evaluationDate` | Which entries are *visible* — filters out entries where `Created > evaluationDate` |

The engine always applies both filters. An entry must satisfy both
conditions to contribute to the payrun result.

```yaml
periodStart:    2026-06-01T00:00:00Z   # what was valid on June 1?
evaluationDate: 2026-02-01T00:00:00Z   # using only data known on Feb 1
```

This is valid configuration — `evaluationDate` may precede `periodStart`.

---

## Entry Selection: Latest Start Date Wins

When multiple entries are visible and valid for a given period, the
engine selects the entry with the latest `Start` date. This is the
same rule in both production and forecast runs.

> **Confirmed by test Retro D:** with `evaluationDate = Today`, both
> entry #1 (start Feb 1) and entry #2 (start Apr 1) are visible on
> June 1. Entry #2 wins because `2026-04-01 > 2026-02-01`.

---

## evaluationDate as a Knowledge Cutoff

An entry is hidden if `Created > evaluationDate`. This means a
retroactive case change entered on May 17 is invisible to any payrun
with `evaluationDate < 2026-05-17` — regardless of the entry's `Start`
date or the payrun's period.

This behaviour is the foundation of audit-safe historical queries:
a payrun with `evaluationDate = periodStart` reproduces exactly what
the system would have calculated on the original run date.

> **Confirmed by tests Retro B and Retro C:** both use `evaluationDate = Feb 1`.
> Entry #2 (created May 17) is invisible in both, even though Retro C
> uses `periodStart = Sep 1` — a date when entry #2 is clearly active
> under today's knowledge.

---

## Forecast Entries Use the Same Resolution Rules

A forecast entry has a `Start`, an optional `End`, and a `Created` date.
The engine applies the same selection rules:

1. `Created ≤ evaluationDate` → visible?
2. `Start ≤ periodStart < End` → valid?
3. Latest `Start` among visible + valid entries wins.

The only difference from a production entry is the `forecast` tag: the
entry is included only when the payrun job carries the matching forecast
name.

> **Confirmed by Forecast C:** the Budget2026 job is active, entry #3 is
> visible — but its `End = 2026-11-30` excludes it from the December
> period. The engine falls back to entry #2 silently. No error is thrown;
> the forecast entry simply does not satisfy the validity condition.

---

## Forecast A vs B: The forecast Parameter as the Sole Differentiator

Forecast A and Forecast B use the same `periodStart` and `evaluationDate`.
Only the `forecast` field differs:

```yaml
# Forecast A — production job, no forecast
jobStatus: Complete
# forecast: (omitted)

# Forecast B — forecast job
jobStatus: Forecast
forecast: Budget2026
```

The result differs (5 500 vs 6 000) solely because the `forecast`
parameter controls whether entry #3 is included in the candidate set.

> This is the cleanest demonstration that the forecast mechanism is
> purely additive: it extends the visible entry set with tagged entries
> without modifying the resolution rules.

---

## evaluationDate ≠ periodStart Is Not an Edge Case

The default pattern in most payruns sets `evaluationDate` to the last
day of the pay period — effectively `evaluationDate ≈ periodStart`.
This example deliberately uses `evaluationDate ≠ periodStart` in four
of seven jobs. Both configurations are fully supported by the engine.

Use cases for explicit `evaluationDate`:

| Use case | Pattern |
|---|---|
| Audit / compliance | `evaluationDate = periodStart` — reproduce what was known at the time |
| Controlling / reporting | `evaluationDate = today` — include all retroactive corrections |
| Forecast | `evaluationDate = periodStart (future)` — include planned changes up to the target date |

---

## Naming Convention for Temporal Test Jobs

```
<PayrunName>.<Perspective>.<Scenario>
```

Examples: `TemporalPayrun.Retro.A`, `TemporalPayrun.Forecast.B`

The perspective prefix (`Retro` / `Forecast`) groups jobs by their
temporal intent in test output and log files.
