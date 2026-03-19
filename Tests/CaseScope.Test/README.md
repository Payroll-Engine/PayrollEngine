# CaseScope.Test

Verifies that wage type scripts correctly read case values from **all three
case scopes** — `National`, `Company`, and `Employee` — and that a change to
a Company-scoped field propagates correctly in the next period without
affecting National values.

Prior to this test, only `Employee`-scoped cases were covered by integration
tests.

---

## Scenario

**Regulation:** `CaseScope.Test`  
**Tenant:** `CaseScope.Test` | **Division:** `CaseScopeDivision` (de-CH)  
**Employee:** `lena.frank@casescope.test`

### Cases

| Case | Scope | Field | Value Type | Time Type |
|:-----|:------|:------|:-----------|:----------|
| `LegalMinimum` | **National** | `MinWageRate` | Money | CalendarPeriod |
| `CompanySettings` | **Company** | `EmployerRate` | Percent | CalendarPeriod |
| `EmployeeContract` | **Employee** | `Salary` | Money | CalendarPeriod |

### Wage Types

| # | Name | Scope used | Expression logic |
|--:|:-----|:-----------|:----------------|
| 101 | `GuardedSalary` | National | `max(Salary, MinWageRate)` — National floor guard |
| 102 | `EmployerContribution` | Company | `Salary × EmployerRate` — Company rate applied |
| 103 | `BaseSalary` | Employee | `Salary` — direct Employee read |

### Case Values

| Scope | Field | Value | Start | Created | Active |
|:------|:------|------:|:------|:--------|:-------|
| National | `MinWageRate` | 24.50 | Jan 1 2024 | Jan 1 2024 | Jan + Feb |
| Company | `EmployerRate` | 0.05 | Jan 1 2024 | Jan 1 2024 | Jan only |
| Company | `EmployerRate` | **0.08** | **Feb 1 2024** | Jan 20 2024 | **Feb onwards** |
| Employee | `Salary` | 5 000 | Jan 1 2024 | Jan 1 2024 | Jan + Feb |

---

## Payrun Jobs

### Job 1 — `Jan24` (evaluationDate: 2024-01-31)

- `MinWageRate` = 24.50 — well below `Salary` 5 000 → floor not triggered
- `EmployerRate` = 0.05
- **Expected:** WT101 = **5 000**, WT102 = **250** (5 000 × 5 %), WT103 = **5 000**

### Job 2 — `Feb24` (evaluationDate: 2024-02-29)

- `MinWageRate` unchanged at 24.50 → WT101 still 5 000
- `EmployerRate` = **0.08** (start Feb 1, created Jan 20 — visible at Feb eval)
- `Salary` unchanged
- **Expected:** WT101 = **5 000**, WT102 = **400** (5 000 × 8 %), WT103 = **5 000**

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| National scope readable in WT | WT101 applies `MinWageRate` floor correctly |
| Company scope readable in WT | WT102 uses `EmployerRate` |
| Employee scope readable in WT | WT103 returns `Salary` directly |
| Company change propagates in next period | WT102 changes Jan 250 → Feb 400 |
| National value unaffected by Company change | WT101 = 5 000 in both periods |

---

## Running the Test

```cmd
cd Tests\CaseScope.Test
pecmd Test.pecmd
```

## See Also

- [Payrun.Test](../Payrun.Test/) — baseline payrun test
- [DerivedPayroll.Test](../DerivedPayroll.Test/) — multi-layer regulation inheritance
