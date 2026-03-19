# PayrunTag.Test

Verifies that **`GetWageTypeResults` with a `Tag` filter** returns only results
stored under that specific tag — and that results stored under a different tag
(or no tag) are not visible.

The tag mechanism is exercised via `ScheduleRetroPayrun(date, tags)`, which
stores the retro sub-run's wage type results under the supplied tag. The query
then filters by that tag in the following main run.

---

## Scenario

**Regulation:** `PayrunTag.Test`  
**Tenant:** `PayrunTag.Test` | **Division:** `PayrunTagDivision` (de-CH)  
**Employee:** `kai.vogel@payruntag.test`

### Wage Types

| # | Name | Clusters | Purpose |
|--:|:-----|:---------|:--------|
| 100 | `Salary` | **Legal** | Base salary — schedules Alpha-tagged retro for the prior period; Legal-only so it never runs in retro sub-runs |
| 110 | `RetroMarker` | Legal, Retro | Returns **750** in retro sub-runs, **0** in main runs |
| 201 | `TagAlphaResult` | Legal | `GetWageTypeResults(WT110, priorPeriod, Tag="Alpha")` |
| 202 | `TagBetaResult` | Legal | `GetWageTypeResults(WT110, priorPeriod, Tag="Beta")` |

WT110 is the distinguishing signal: it produces a non-zero value **only** inside
a retro sub-run. WT201 and WT202 read it back with different tag filters.

### Case Values

| Field | Value | Start | Created |
|:------|------:|:------|:--------|
| Salary | 5 000 | Jan 1 2018 | Jan 1 2018 |

Salary is open-ended from Jan 2018 — every period in the test sequence has a valid value.

---

## Payrun Jobs

### Job 1 — `Nov18` (evaluationDate: 2018-11-28)

- WT100 schedules an Alpha-tagged retro sub-run for **October 2018**
- Oct retro Alpha sub-run: **WT110=750** (`IsRetroPayrun=true`); WT100 not in Retro cluster — does not run
- Nov main run: WT100=5 000, WT110=0
- WT201 queries Oct Alpha WT110 → **750** (Alpha tag found)
- WT202 queries Oct Beta WT110 → **0** (no Beta retro was ever scheduled)

| WT | Expected | Key assertion |
|---:|---------:|:--------------|
| 100 | 5 000 | Current salary |
| 110 | 0 | Main run — not a retro sub-run |
| 201 | **750** | Alpha-tagged Oct retro result found |
| 202 | **0** | Beta tag absent — no Beta retro was ever created |

> WT201=750 and WT202=0 together prove tag isolation:
> the Alpha result is readable via its tag and invisible via any other tag.

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| Tagged retro result is queryable by its tag | WT201 = 750 |
| Non-existent tag returns empty (zero) | WT202 = 0 |
| Retro sub-run stored WT110=750 under Alpha tag | retro result WT110 = 750 |
| Main run stored WT110=0 (no tag) | main WT110 = 0 |
| WT100 (Legal-only) does not run in retro sub-run | only WT110 in Oct retro results |

---

## Running the Test

```cmd
cd Tests\PayrunTag.Test
pecmd Test.pecmd
```

## See Also

- [RetroManualPayroll.Test](../RetroManualPayroll.Test/) — tag-per-retro-period pattern (different periods)
- [RetroPayroll.Test](../RetroPayroll.Test/) — comprehensive retro scenarios
- [Payrun Model — Retroactive Calculation](../../docs/PayrunModel.md)
