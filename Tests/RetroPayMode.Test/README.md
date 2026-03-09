# RetroPayMode.Test

Verifies that `retroPayMode` on a payrun job invocation controls whether
retroactive sub-runs are created when case value mutations in prior periods
are detected.

## Scenario

**Regulation:** `RetroPayMode.Test`  
**Tenant:** `RetroPayMode.Test` | **Division:** `RetroPayModeDivision` (de-CH)  
**Employee:** `retro.employee@foo.com`

### Wage Types

| # | Name | Clusters | Purpose |
|--:|:-----|:---------|:--------|
| 101 | Salary | Legal, Retro | Base salary — re-executed in retro sub-runs |
| 102 | SalaryRetroDiff | Legal | Retro delta: `GetWageTypeRetroResultSum(101)` |
| 103 | IsRetroIndicator | Legal, Retro | Returns `1` inside a retro sub-run, `0` in main runs |

### Case Values

| Field | Value | Start | Created | Visible from |
|:------|------:|:------|:--------|:-------------|
| Salary | 3000 | Jan 1 2024 | Dec 1 2023 | always |
| Salary | 3000 | Feb 1 2024 | Jan 15 2024 | always |
| Salary | 3000 | Mar 1 2024 | Feb 1 2024 | always |
| Salary | **4000** | Jan 1 2024 | **Feb 15 2024** | EvalDate ≥ Feb 15 |

The last entry is the retro-triggering mutation: it changes the January salary
retroactively and becomes visible starting with the February 2024 evaluation date.

## Payrun Jobs

### Job 1 — `Jan24` (retroPayMode: ValueChange, default)

- **EvalDate:** 2024-01-28 — retro change (created Feb 15) not yet visible
- **Expected:** WT101=3000, WT102=0 (no sub-run), WT103=0

### Job 2 — `Feb24.None` (retroPayMode: **None**)

- **EvalDate:** 2024-02-28 — retro change (created Feb 15) now visible
- **Expected:** WT101=3000, WT102=**0**, WT103=0
- **Key assertion:** despite the Jan mutation being detectable, `retroPayMode=None`
  suppresses the retro sub-run entirely → SalaryRetroDiff remains 0

### Job 3 — `Mar24.ValueChange` (retroPayMode: **ValueChange**, default)

- **EvalDate:** 2024-03-28 — Jan mutation still unprocessed (Feb run was `None`)
- **Expected main:** WT101=3000, WT102=**1000**, WT103=0
- **Expected retro sub-run (Jan 2024):** WT101=4000, WT103=**1**
- **Key assertion:** `retroPayMode=ValueChange` triggers the retro sub-run for Jan;
  delta = 4000 − 3000 = +1000 collected in WT102; `IsRetroIndicator=1` confirms
  the sub-run was executed

## RetroPayMode Values

| Value | Behaviour |
|:------|:----------|
| `ValueChange` | Default. Retro sub-runs are created for all prior periods where case value mutations are detected since the last payrun. |
| `None` | Retro detection is skipped entirely. The payrun runs as if no prior-period mutations exist. Useful for correction runs or testing main-run logic in isolation. |

> **Note:** `RetroTimeType` (`Anytime` / `Cycle`) is a separate payrun-level property
> that controls *how far back* retro detection reaches; it is independent of
> `retroPayMode`.

## Running the Test

```cmd
cd Tests\RetroPayMode.Test
PayrunTest Payroll.pt.json

# or via Test.All:
# Test.All.pecmd includes RetroPayMode.Test/Test.pecmd
```

## See Also

- [RetroPayroll.Test](../RetroPayroll.Test/) — comprehensive retro payroll scenario
- [RetroManualPayroll.Test](../RetroManualPayroll.Test/) — manually triggered retro runs
- [Payrun Model — Retroactive Calculation](../../docs/PayrunModel.md)
