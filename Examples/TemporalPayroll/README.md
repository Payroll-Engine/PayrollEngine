# Temporal Payroll Example

A focused example for **TemporalAG**, demonstrating the two independent
time axes of case value resolution in PayrollEngine.

One wage type. Seven payrun jobs. All complexity lives in the combination
of `periodStart` (valueDate) and `evaluationDate`.

---

## The Two Time Axes

| Parameter | Question answered |
|---|---|
| `periodStart` (valueDate) | Which value was **active** on this date? |
| `evaluationDate` | Which entries were **known** on this date? |

Each payrun job sets these two parameters independently. The combination
determines the **temporal perspective** of the result.

---

## Test Data

One employee (`Alex Meyer`), one case field (`Salary`), three entries:

| # | Created | Valid from | Valid to | Value | Forecast |
|---|---|---|---|---|---|
| 1 | 2026-01-12 | 2026-02-01 | open | 5 000 | — |
| 2 | 2026-05-17 | 2026-04-01 | open | 5 500 | — |
| 3 | 2026-07-13 | 2026-10-01 | 2026-11-30 | 6 000 | Budget2026 |

Reference point: **Now = 2026-09-30** (used as `evaluationDate` for "Today" scenarios).

---

## Regulation: TemporalRegulation

### Case

| Case | Type | Field | Value type | Time type |
|---|---|---|---|---|
| `Salary` | Employee | Salary | Money | CalendarPeriod |

### Wage Type

| # | Name | Action | Collector |
|---|---|---|---|
| 100 | Salary | `^^Salary` | GrossIncome |

A single No-Code action reads the salary case value. The engine resolves
which entry to return based on the payrun's `periodStart` and `evaluationDate`.

---

## Retro Scenarios (production, no forecast)

The four retro scenarios form a 2×2 matrix across the two time axes.
Each scenario is a standard production payrun job — no retro engine
recalculation is involved. The term "retro" refers to looking at
historical periods through different knowledge lenses.

| Job | EvalDate | ValueDate | Visible entries | Result |
|---|---|---|---|---|
| Retro A | Today | Today | #1 + #2 | **5 500** |
| Retro B | Feb 1 | Jun 1 | #1 only | **5 000** |
| Retro C | Feb 1 | Today | #1 only | **5 000** |
| Retro D | Today | Jun 1 | #1 + #2 | **5 500** |

**Key observation:** Retro B and Retro D use the same `periodStart` (June)
but different `evaluationDate` values and return different results. Entry
#2 (created May 17) is invisible when `evaluationDate = Feb 1` — it did
not exist in the system at that point.

### 2×2 Matrix

```
                  ValueDate = Past (Jun 1)   ValueDate = Today (Sep)
EvalDate = Past   Retro B → 5 000            Retro C → 5 000
EvalDate = Today  Retro D → 5 500            Retro A → 5 500
```

---

## Forecast Scenarios

| Job | EvalDate | ValueDate | Forecast | Visible | Result |
|---|---|---|---|---|---|
| Forecast A | Oct 31 | Oct 1 | — | #1 + #2 | **5 500** |
| Forecast B | Oct 31 | Oct 1 | Budget2026 | #1 + #2 + #3 | **6 000** |
| Forecast C | Dec 31 | Dec 1 | Budget2026 | #1 + #2 + #3 | **5 500** |

**Forecast A vs B:** identical period and evaluation date — the only
difference is the `forecast` parameter. Entry #3 is tagged `Budget2026`
and is invisible to production runs. The forecast job activates it.

**Forecast C:** entry #3 expires on 2026-11-30. The December payrun falls
outside its validity period, so entry #2 wins despite Budget2026 being
active. A forecast entry has the same `Start`/`End` semantics as a
production entry.

---

## Calculated Results

### Retro A — EvalDate = Today · ValueDate = Sep

Both entries #1 and #2 are visible (`created ≤ Sep 30`). On September 1
entry #2 (valid from Apr 1, open-ended) has the latest start date and wins.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 500** | **5 500** |

### Retro B — EvalDate = Feb 1 · ValueDate = Jun

Entry #2 was created 2026-05-17 > 2026-02-01 → invisible. Only entry #1
(created Jan 12) is visible. On June 1 entry #1 is still open-ended.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 000** | **5 000** |

### Retro C — EvalDate = Feb 1 · ValueDate = Sep

Same knowledge cutoff as Retro B. Entry #1 is still open-ended, so it
covers September as well — the system has no awareness of entry #2.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 000** | **5 000** |

### Retro D — EvalDate = Today · ValueDate = Jun

Today's knowledge: both entries visible. On June 1 entry #2 (from Apr 1)
has a later start date than entry #1 (from Feb 1) and wins.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 500** | **5 500** |

### Forecast A — EvalDate = Oct 31 · ValueDate = Oct · no forecast

No forecast name on the job — entry #3 is excluded. Entry #2 is
open-ended and covers October.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 500** | **5 500** |

### Forecast B — EvalDate = Oct 31 · ValueDate = Oct · Budget2026

Forecast Budget2026 is active. Entry #3 (Oct 1–Nov 30) is included and
covers October — it has the latest start date among visible entries.

| WT 100 Salary | GrossIncome |
|---|---|
| **6 000** | **6 000** |

### Forecast C — EvalDate = Dec 31 · ValueDate = Dec · Budget2026

Entry #3 ends 2026-11-30. December 1 falls outside its validity window,
so the engine skips it and returns to entry #2.

| WT 100 Salary | GrossIncome |
|---|---|
| **5 500** | **5 500** |

---

## Key Design Decisions

### One wage type — all complexity in the payrun invocations

The regulation is intentionally minimal. A single `^^Salary` action
reads the salary case value. The engine's resolution logic — which entry
wins — is entirely determined by `periodStart` and `evaluationDate` on
the payrun job. This makes the temporal mechanism the sole subject of
the example, without distraction from delta wage types, collectors,
or scripted expressions.

### evaluationDate may precede periodStart

Retro B and Retro C set `evaluationDate` earlier than `periodStart`.
This is a deliberate and valid configuration — it models the question
"what would the payrun have returned if run at a historical knowledge
cutoff?" The engine treats the two parameters as fully independent axes.

### Forecast entry expiry is a first-class test case

Forecast C demonstrates that a forecast entry's `End` date is enforced
exactly like a production entry's. The Budget2026 scenario remains active
(the job carries `forecast: Budget2026`) but entry #3 has expired.
The engine returns entry #2, not 6 000, and not an error. This is the
expected production behaviour for planned salary increases with a defined
validity window.

### No retro engine involvement

The four "Retro" jobs are standard `jobStatus: Complete` invocations.
They do not trigger the PayrollEngine retro recalculation mechanism
(no `retroJobs` list, no delta wage types, no cluster sets). The word
"retro" in job names refers to the conceptual temporal perspective, not
to the PE retro payroll feature. See `RetroPayroll` for the full retro
delta mechanism.

---

## Files

| File | Purpose |
|---|---|
| `Payroll.tp.yaml` | Complete self-contained payroll test (tenant · regulation · data · results) |
| `BestPractices.md` | Temporal perspective patterns and design notes |
| `Setup.pecmd` | Full setup: delete + import |
| `Delete.pecmd` | Remove the TemporalAG tenant |
| `Test.pecmd` | Delete + run PayrunTest |

## Commands

```
# Full setup
Setup.pecmd

# Run test
Test.pecmd

# Teardown
Delete.pecmd
```

---

## Features Demonstrated

- **Two independent time axes** — `periodStart` (valueDate) and `evaluationDate` operate independently; their combination defines the temporal perspective of the result
- **Knowledge cutoff isolation** — setting `evaluationDate` to a past date hides entries created after that point, even when `periodStart` is later
- **Retro 2×2 matrix** — four scenarios cover all combinations of past/today for both axes, exposing the exact impact of each axis independently
- **Forecast entry with validity window** — entry #3 has an `End` date; Forecast C demonstrates that the engine respects it and falls back to the production value after expiry
- **Forecast vs production isolation** — Forecast A and B use the same period and evaluation date; the `forecast` parameter alone controls whether entry #3 is visible
- **Minimal regulation, maximal clarity** — one case field, one wage type, seven payrun jobs; the temporal mechanism is the sole subject
