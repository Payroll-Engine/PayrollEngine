# Timeless.Test

Regression test for the **timeless case value codepath** — verifies that wage
type scripts can safely read `Timeless` fields across multiple payrun periods,
including the case where an optional timeless field has not yet been set.

This test was introduced after a `NullReferenceException` was fixed in the
timeless value resolution path.

---

## Scenario

**Regulation:** `Timeless.Test`  
**Tenant:** `Timeless.Test` | **Division:** `TimelessDivision` (de-CH)  
**Employee:** `maja.berger@timeless.test`

### Cases

| Case | Type | Field | Value Type | Time Type |
|:-----|:-----|:------|:-----------|:----------|
| `PersonalData` | Employee | `BirthDate` | Date | **Timeless** |
| `PersonalData` | Employee | `TaxCode` | String | **Timeless** |
| `Salary` | Employee | `Salary` | Money | CalendarPeriod |

### Wage Types

| # | Name | Purpose |
|--:|:-----|:--------|
| 101 | `AgeAllowance` | Reads `BirthDate` (Timeless) every period — 7.5 % allowance if age ≥ 50 at PeriodEnd |
| 102 | `TaxAmount` | Reads `TaxCode` (Timeless, optional) — null-safe; 0 when absent, rate A=5 % / B=8 % |

### Case Values

| Field | Value | Created | Note |
|:------|:------|:--------|:-----|
| `BirthDate` | 1971-03-12 | 2024-01-01 | Set once before Jan job — stable across all periods |
| `TaxCode` | `"A"` | 2024-02-15 | Set between Jan and Feb evaluation dates |
| `TaxCode` | `"B"` | 2024-03-01 | Set between Feb and Mar evaluation dates — latest wins |
| `Salary` | 6 000 | 2024-01-01 | Active from Jan 1 (CalendarPeriod) |

> **Timeless fields** have no `start`/`end` — a `created` timestamp is the
> sole ordering key. The value with the highest `created` ≤ `evaluationDate`
> is the active value for that run.

---

## Payrun Jobs

### Job 1 — `Jan24` (evaluationDate: 2024-01-31)

- `BirthDate` visible → age at Jan 31 = 52 → AgeAllowance applies
- `TaxCode` **not yet set** (created Feb 15 > Jan 31) → null path exercised
- **Expected:** WT101 = **450** (6 000 × 7.5 %), WT102 = **0**

### Job 2 — `Feb24` (evaluationDate: 2024-02-29)

- `BirthDate` unchanged → WT101 still 450
- `TaxCode = "A"` now visible (created Feb 15 ≤ Feb 29) → rate 5 %
- **Expected:** WT101 = **450**, WT102 = **300** (6 000 × 5 %)

### Job 3 — `Mar24` (evaluationDate: 2024-03-31)

- `BirthDate` unchanged → WT101 still 450
- `TaxCode = "B"` wins (created Mar 1, later than "A") → rate 8 %
- **Expected:** WT101 = **450**, WT102 = **480** (6 000 × 8 %)

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| Timeless field readable in every period without exception | WT101 = 450 in all 3 jobs |
| `null` timeless field returns 0, no NullReferenceException | WT102 = 0 in Jan job |
| Latest `created` value wins for timeless fields | WT102 switches A → B between Feb and Mar |

---

## Script Notes

`CaseValue[field]` returns `null` when a timeless field has not yet been set.
Use `ValueAs<T>()` to read the typed value — **not** `.Value` (type `object`):

```csharp
// correct
var code = tc.ValueAs<string>();

// wrong — CS1503: cannot convert object to string?
string.IsNullOrEmpty(tc.Value)
```

---

## Running the Test

```cmd
cd Tests\Timeless.Test
pecmd Test.pecmd
```

## See Also

- [Payrun.Test](../Payrun.Test/) — baseline payrun test
- [PayrunEdge.Test](../PayrunEdge.Test/) — temporal boundary cases
