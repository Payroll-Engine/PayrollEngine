# MultiDivision.Test

Verifies that **division-scoped case values are correctly isolated** per payroll:
one employee assigned to two divisions receives a different salary in each, and
each division's payrun reads only its own value.

---

## Scenario

**Regulation:** `MultiDivision.Test`  
**Tenant:** `MultiDivision.Test` | **Divisions:** `DE` (de-DE), `CH` (de-CH)  
**Employee:** `max.keller@multidivision.test` — assigned to **both** divisions

### Case Field

| Case | Field | Scope | Time Type |
|:-----|:------|:------|:----------|
| `EmployeeContract` | `Salary` | Employee (default) | CalendarPeriod |

Each case change carries a `divisionName`. The engine resolves case values
scoped to the division of the running payroll. The same employee can carry
different salary values for DE and CH simultaneously.

### Division Case Values

| Division | Field | Value | Start | Created |
|:---------|:------|------:|:------|:--------|
| **DE** | Salary | 4 000 | Jan 1 2024 | Jan 1 2024 |
| **CH** | Salary | 6 000 | Jan 1 2024 | Jan 1 2024 |

### Wage Types

| # | Name | Expression |
|--:|:-----|:-----------|
| 101 | `Salary` | `CaseValue["Salary"]` |
| 102 | `SalaryDoubled` | `WageType[101] * 2` |

WT102 provides a second assertion point: if the wrong division value were resolved,
both WT101 and WT102 would be wrong simultaneously, making the failure unambiguous.

---

## Payrun Jobs

### Job 1 — `MultiDivision.DE.Jan24`

| | |
|:--|:--|
| Payroll / Division | `MultiDivision.DE.Payroll` / **DE** |
| `periodStart` | 2024-01-01 |
| `evaluationDate` | 2024-01-28 |

| WT | Expected | |
|---:|---------:|:--|
| 101 | **4 000** | DE salary |
| 102 | **8 000** | 4 000 × 2 |

### Job 2 — `MultiDivision.CH.Jan24`

| | |
|:--|:--|
| Payroll / Division | `MultiDivision.CH.Payroll` / **CH** |
| `periodStart` | 2024-01-01 |
| `evaluationDate` | 2024-01-28 |

| WT | Expected | |
|---:|---------:|:--|
| 101 | **6 000** | CH salary |
| 102 | **12 000** | 6 000 × 2 |

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| DE payroll resolves DE salary only | WT101 DE = 4 000 |
| CH payroll resolves CH salary only | WT101 CH = 6 000 |
| CH salary invisible to DE payroll | WT101 DE ≠ 6 000 |
| DE salary invisible to CH payroll | WT101 CH ≠ 4 000 |
| Calculation uses correct base | WT102 DE = 8 000, WT102 CH = 12 000 |

---

## Running the Test

```cmd
cd Tests\MultiDivision.Test
pecmd Test.pecmd
```

## See Also

- [CaseScope.Test](../CaseScope.Test/) — National / Company / Employee scope isolation
- [CountryPayroll.Test](../CountryPayroll.Test/) — multi-country payroll with shared base regulation
- [Payrun Model](../../docs/PayrunModel.md)
