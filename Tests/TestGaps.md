# Test Coverage Gaps

Remaining integration tests identified in gap analysis.  
`RetroPayMode.Test` and `SlotValue.Test` are resolved or deferred — not listed.

---

## Priority 1 — Missing entirely

### Timeless.Test

**Type:** Payrun  
**Regression for:** NullReferenceException in timeless case value codepath (recently fixed)

| Case field | timeType | Scenario |
|:-----------|:---------|:---------|
| `BirthDate` | Timeless | Set once, read in every period |
| `TaxCode` | Timeless | Changed mid-sequence, verify latest value wins |

**Jobs:** 3 periods (Jan–Mar), one timeless change between Feb and Mar  
**Key assertions:** WT reads timeless value correctly in all periods; no NullRef on absent optional timeless field

---

## Priority 2 — Partial coverage

### CaseScope.Test

**Type:** Payrun  
**Gap:** All existing tests use `Employee` cases only — `Company` and `National` scope untested

| Scope | Case | Value | Used in WT |
|:------|:-----|:------|:-----------|
| National | `MinWageRate` | 24.50 | WT101 floor guard |
| Company | `EmployerRate` | 0.05 | WT102 = Salary × rate |
| Employee | `Salary` | 5000 | WT103 base |

**Jobs:** Jan + Feb (Company rate change in Feb)  
**Key assertions:** Each WT reads from the correct scope; Company change in Feb propagates correctly without affecting National values

---

### VersionEdge.Test

**Type:** Payrun  
**Gap:** `VersionPayroll.Test` covers normal version sequencing — `validFrom == evaluationDate` and `validFrom > evaluationDate` boundary cases are untested

| Scenario | validFrom | evaluationDate | Expected |
|:---------|:----------|:---------------|:---------|
| Same-day activation | 2024-02-01 | 2024-02-01 | New version **active** (≤) |
| Future version | 2024-03-01 | 2024-02-28 | New version **not active** |

**Jobs:** Jan / Feb / Mar  
**Key assertions:** Version with `validFrom == evalDate` is derived; version with `validFrom > evalDate` is not

---

## Priority 3 — Nice to have

### ConsolidatedEdge.Test

**Type:** Payrun  
**Gap:** `consolidatedPayMode: ValueChange` semantics and `NoRetro` flag interaction untested in isolation

| Scenario | consolidatedPayMode | NoRetro | Expected behaviour |
|:---------|:--------------------|:--------|:-------------------|
| Default | ValueChange | false | Retro results included in consolidated view |
| NoRetro | ValueChange | true | Retro results excluded; only main-run value |

---

### PayrunTag.Test

**Type:** Payrun  
**Gap:** Tag-filtered result queries used implicitly in `RetroManualPayroll.Test` — never tested in isolation

**Scenario:** Run two jobs for the same period with different tags; verify `GetWageTypeResults` with tag filter returns only the tagged subset

---

### MultiDivision.Test

**Type:** Payrun  
**Gap:** Employee assigned to multiple divisions — division-specific case values never isolated

**Scenario:** One employee, two divisions (`DE`, `CH`), division-scoped salary; verify correct value is used per division payroll

---

## Status

| Test | Priority | Status |
|:-----|:---------|:-------|
| `Timeless.Test` | 1 | Open |
| `CaseScope.Test` | 2 | Open |
| `VersionEdge.Test` | 2 | Open |
| `ConsolidatedEdge.Test` | 3 | Open |
| `PayrunTag.Test` | 3 | Open |
| `MultiDivision.Test` | 3 | Open |
| `SlotValue.Test` | 1 | Deferred (selten verwendet) |
