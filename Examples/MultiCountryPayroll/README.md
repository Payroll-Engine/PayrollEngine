# Multi-Country Payroll Example

A practical international payroll example for **ACME International**, a fictitious
technology company paying salaries in Germany, France, and the Netherlands.

Demonstrates multi-country regulation layers, global case values, and a split-country
employee who receives salary from two national payrolls simultaneously.

---

## Architecture

```
ACME.Global  (shared base regulation — level 1 in all payrolls)
    │
    ├── ACME.DE  (level 2)   ──►  ACME.Payroll.DE  ──►  ACME.Payrun.DE
    ├── ACME.FR  (level 2)   ──►  ACME.Payroll.FR  ──►  ACME.Payrun.FR
    └── ACME.NL  (level 2)   ──►  ACME.Payroll.NL  ──►  ACME.Payrun.NL
```

Each country payroll uses **two regulation layers**:
- **Level 1 — ACME.Global**: global cases (Salary, EmploymentLevel, CompanyBonus),
  global wage types (WT 100, 110), and shared collectors (Gross Income, Deductions)
- **Level 2 — ACME.xx**: country-specific national cases and deduction wage types (WT 200+)

---

## Employees

| Employee | Division(s) | Salary | Level | Country scenario |
|---|---|---|---|---|
| Anna Weber | ACME.DE | 5 600 | 100 % | Germany only |
| Pierre Dubois | ACME.FR | 4 800 | 100 % | France only |
| Lucas de Vries | ACME.NL | 5 200 | 100 % | Netherlands only |
| **Sophie Klein** | **ACME.DE + ACME.FR** | **8 000** | **60 % DE + 40 % FR** | **Split across two countries** |

Sophie Klein's `Salary` field carries `valueScope: Global` — it is set once and read
by both the German and French payroll runs. Her `EmploymentLevel` is set separately
per division (0.6 in ACME.DE, 0.4 in ACME.FR).

---

## Regulations

### ACME.Global — Shared Base

| Element | Type | Detail |
|---|---|---|
| `CompanyBonus` | Company case | `CompanyBonus Rate` — Percent, CalendarPeriod, **valueScope: Global** |
| `Salary` | Employee case | `Salary` — Money, CalendarPeriod, **valueScope: Global** |
| `EmploymentLevel` | Employee case | `EmploymentLevel` — Percent, Period (per division) |
| WT 100 Base Salary | WageType | `Salary × EmploymentLevel` → Gross Income |
| WT 110 Company Bonus | WageType | `WT100 × CompanyBonus Rate` → Gross Income |
| `Gross Income` | Collector | Aggregates WT 100 + WT 110 |
| `Deductions` | Collector | Aggregates all country deduction wage types |

### ACME.DE — Germany Layer

| Element | Type | Rate |
|---|---|---|
| `DE IncomeTax` | National case | `DE IncomeTax Rate` (Percent, Period) |
| `DE SocialInsurance` | National case | `DE SocialInsurance Rate` (Percent, Period) |
| WT 200 DE Income Tax | WageType | `Gross Income × 25 %` → Deductions |
| WT 210 DE Social Insurance | WageType | `Gross Income × 20 %` → Deductions |

### ACME.FR — France Layer

| Element | Type | Rate |
|---|---|---|
| `FR IncomeTax` | National case | `FR IncomeTax Rate` (Percent, Period) |
| `FR CSG` | National case | `FR CSG Rate` (Percent, Period) |
| `FR FamilyContribution` | National case | `FR FamilyContribution Rate` (Percent, Period) |
| WT 200 FR Income Tax | WageType | `Gross Income × 20 %` → Deductions |
| WT 210 FR CSG/CRDS | WageType | `Gross Income × 10 %` → Deductions |
| WT 220 FR Family Contribution | WageType | `Gross Income × 5 %` → Deductions |

### ACME.NL — Netherlands Layer

| Element | Type | Rate |
|---|---|---|
| `NL IncomeTax` | National case | `NL IncomeTax Rate` (Percent, Period) |
| `NL AOW` | National case | `NL AOW Rate` (Percent, Period) |
| `NL ZVW` | National case | `NL ZVW Rate` (Percent, Period) |
| WT 200 NL Income Tax | WageType | `Gross Income × 30 %` → Deductions |
| WT 210 NL AOW Pension | WageType | `Gross Income × 20 %` → Deductions |
| WT 220 NL ZVW Health | WageType | `Gross Income × 5 %` → Deductions |

---

## Configured Rates (January 2024)

| Parameter | Value |
|---|---|
| Company Bonus Rate | 5 % (global) |
| DE Income Tax | 25 % |
| DE Social Insurance | 20 % |
| FR Income Tax | 20 % |
| FR CSG/CRDS | 10 % |
| FR Family Contribution | 5 % |
| NL Income Tax | 30 % |
| NL AOW Pension | 20 % |
| NL ZVW Health | 5 % |

---

## Calculated Results — January 2024

### Germany Payroll

| | Anna Weber | Sophie Klein (DE) |
|---|---|---|
| Salary | 5 600 | 8 000 (global) |
| Employment Level | 100 % | 60 % |
| **WT 100 Base Salary** | **5 600** | **4 800** |
| **WT 110 Company Bonus** | **280** | **240** |
| **Gross Income** | **5 880** | **5 040** |
| WT 200 DE Income Tax (25 %) | 1 470 | 1 260 |
| WT 210 DE Social Insurance (20 %) | 1 176 | 1 008 |
| **Deductions** | **2 646** | **2 268** |
| **Net Pay** | **3 234** | **2 772** |

### France Payroll

| | Pierre Dubois | Sophie Klein (FR) |
|---|---|---|
| Salary | 4 800 | 8 000 (global) |
| Employment Level | 100 % | 40 % |
| **WT 100 Base Salary** | **4 800** | **3 200** |
| **WT 110 Company Bonus** | **240** | **160** |
| **Gross Income** | **5 040** | **3 360** |
| WT 200 FR Income Tax (20 %) | 1 008 | 672 |
| WT 210 FR CSG/CRDS (10 %) | 504 | 336 |
| WT 220 FR Family Contribution (5 %) | 252 | 168 |
| **Deductions** | **1 764** | **1 176** |
| **Net Pay** | **3 276** | **2 184** |

### Netherlands Payroll

| | Lucas de Vries |
|---|---|
| Salary | 5 200 |
| Employment Level | 100 % |
| **WT 100 Base Salary** | **5 200** |
| **WT 110 Company Bonus** | **260** |
| **Gross Income** | **5 460** |
| WT 200 NL Income Tax (30 %) | 1 638 |
| WT 210 NL AOW Pension (20 %) | 1 092 |
| WT 220 NL ZVW Health (5 %) | 273 |
| **Deductions** | **3 003** |
| **Net Pay** | **2 457** |

### Sophie Klein — Combined View

Sophie's total compensation across both countries:

| | DE portion | FR portion | Total |
|---|---|---|---|
| Base Salary | 4 800 | 3 200 | **8 000** |
| Company Bonus | 240 | 160 | **400** |
| Gross Income | 5 040 | 3 360 | **8 400** |
| Deductions | 2 268 | 1 176 | **3 444** |
| Net Pay | 2 772 | 2 184 | **4 956** |

---

## Files

| File | Purpose |
|---|---|
| `Payroll.json` | Tenant, all 4 regulations, 3 payrolls (with national rates), 3 payruns |
| `Payroll.Values.json` | Employee case values (salary, employment level per division) |
| `Payroll.Jobs.json` | Payrun job invocations for Jan + Feb 2024 (all 3 countries) |
| `Test.et.json` | Employee payroll test — 5 result sets across 3 payrun jobs |
| `Setup.pecmd` | Full setup: delete → import → password → values → jobs |
| `Delete.pecmd` | Remove the ACME.International tenant |
| `Import.pecmd` | Import regulation and payroll structure |
| `Import.Values.pecmd` | Import employee case values |
| `Import.Jobs.pecmd` | Import and run payrun jobs |
| `Test.pecmd` | Run employee payroll test |

---

## Commands

```
# Full setup
Setup.pecmd

# Run all tests (3 payrun jobs, 5 employee result sets)
Test.pecmd

# Teardown
Delete.pecmd
```

---

## Web Application Login

| Field | Value |
|---|---|
| User | `admin@acme-international.com` |
| Password | `@ayroll3nginE` |

---

## Key Design Decisions

### Global Salary via valueScope
`Salary.valueScope = Global` allows Sophie's single salary record (set via the DE
payroll) to be read without duplication by the FR payroll. Without this, the same
value would need to be maintained separately per country payroll — a data consistency risk.

### Per-Division EmploymentLevel
`EmploymentLevel` is intentionally NOT global, enabling independent percentages per
country. Sophie's 60 % / 40 % split is expressed as two separate case values in
ACME.DE and ACME.FR respectively.

### Shared Regulation (ACME.Global)
`sharedRegulation: true` marks ACME.Global as reusable infrastructure. All three
country payrolls reference it at level 1 — any change to the global bonus rate or
base salary logic propagates automatically to all countries.

### Wage Type Numbering Convention
- **WT 100–199**: global income components (same number in every payroll)
- **WT 200–299**: country deductions (same number meaning different calculation per country, no collision because each regulation lives in its own payroll)

### Collectors as Consolidation Layer
`Gross Income` and `Deductions` are defined once in ACME.Global and inherited by all
country regulations. Country-specific deduction wage types write into `Deductions`,
making per-payroll net pay trivially computable as `Gross Income − Deductions`.
