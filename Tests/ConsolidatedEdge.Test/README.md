# ConsolidatedEdge.Test

Tests the **`NoRetro` flag on `GetConsolidatedWageTypeResults`** — verifying that
the flag correctly includes or excludes retro sub-run results from the consolidated
prior-period view.

| Scenario | `NoRetro` | Expected Jan result in Feb query |
|:---------|:----------|:---------------------------------|
| Default | `false` | Jan **retro value** included → 6 000 |
| NoRetro | `true` | Jan **main-run value** only → 5 000 |

---

## Scenario

**Regulation:** `ConsolidatedEdge.Test`  
**Tenant:** `ConsolidatedEdge.Test` | **Division:** `ConsolidatedEdgeDivision` (de-CH)  
**Employee:** `anna.bauer@consolidatededge.test`

### Wage Types

| # | Name | Clusters | Purpose |
|--:|:-----|:---------|:--------|
| 101 | `Salary` | Legal, Retro | Base salary — re-executed in retro sub-runs |
| 102 | `SalaryRetroDiff` | Legal | Retro delta: `GetWageTypeRetroResultSum(101)` |
| 103 | `ConsolidatedWithRetro` | Legal | `GetConsolidatedWageTypeResults` NoRetro=false (default) |
| 104 | `ConsolidatedNoRetro` | Legal | `GetConsolidatedWageTypeResults` NoRetro=true |

### Case Values

| Field | Value | Start | Created | Visible from | Active in |
|:------|------:|:------|:--------|:-------------|:----------|
| Salary | 5 000 | Jan 1 2024 | Dec 1 2023 | always | Jan onwards |
| Salary | 5 000 | Feb 1 2024 | Jan 15 2024 | always | Feb onwards |
| Salary | **6 000** | Jan 1 2024 | **Feb 15 2024** | EvalDate ≥ Feb 15 | Jan ← retro trigger |
| Salary | 5 000 | Feb 1 2024 | **Feb 20 2024** | EvalDate ≥ Feb 20 | Feb ← pins Feb to 5 000 |

The Jan retro trigger (6 000, created Feb 15) would otherwise also win for February
(it's open-ended from Jan 1). The Feb 20 override (5 000, created Feb 20) is later,
so February stays at 5 000.

---

## Payrun Jobs

### Job 1 — `Jan24` (evaluationDate: 2024-01-28)

- Only the Dec 1 entry is visible — Salary = 5 000
- No prior completed periods → WT103 = 0, WT104 = 0

| WT | Expected |
|---:|---------:|
| 101 | 5 000 |
| 102 | 0 |
| 103 | 0 |
| 104 | 0 |

### Job 2 — `Feb24` (evaluationDate: 2024-02-28)

- Retro change (6 000, created Feb 15) triggers a retro sub-run for January
- Jan retro sub-run: WT101 = **6 000**
- Feb main run: WT101 = 5 000 (Feb 20 entry wins for Feb)
- WT102 = 1 000 (retro delta: 6 000 − 5 000)

| WT | Expected | Key assertion |
|---:|---------:|:--------------|
| 101 | 5 000 | Feb salary unaffected by Jan retro |
| 102 | 1 000 | Retro delta correctly accumulated |
| 103 | **6 000** | Consolidated Jan **with** retro = 6 000 |
| 104 | **5 000** | Consolidated Jan **without** retro = 5 000 (original main run) |

> WT103 ≠ WT104 is the core assertion: the NoRetro flag changes which
> Jan result is returned.

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| `NoRetro=false` returns retro-corrected prior value | WT103 Feb = 6 000 |
| `NoRetro=true` returns original main-run value | WT104 Feb = 5 000 |
| Retro sub-run executed | retro result Jan → WT101 = 6 000 |
| Retro delta correct | WT102 Feb = 1 000 |
| Feb main run unaffected by NoRetro flag | WT101 Feb = 5 000 |

---

## Running the Test

```cmd
cd Tests\ConsolidatedEdge.Test
pecmd Test.pecmd
```

## See Also

- [ConsolidatedPayroll.Test](../ConsolidatedPayroll.Test/) — YTD accumulation baseline
- [RetroPayMode.Test](../RetroPayMode.Test/) — retroPayMode flag behaviour
- [RetroPayroll.Test](../RetroPayroll.Test/) — comprehensive retro scenarios
