# Global Payroll Example

A practical international payroll example for a fictitious technology company **GlobalTech**.  
Demonstrates the core PayrollEngine features without any country-specific regulation dependency.

> This example also serves as a reference for **LLM-assisted regulation development**.  
> See `Prompt.md` for the natural language requirements that were used to generate this regulation.

---

## Scenario

GlobalTech employs software engineers across different employment levels.  
Two employees represent typical real-world configurations:

| Employee | Salary | Level | Born | Key scenario |
|---|---|---|---|---|
| Sarah Chen | 6 000 | 100 % | 1985-08-20 | Full-time, performance bonus in January |
| Carlos Rodriguez | 10 000 | 60 % | 1970-07-15 | Part-time, senior supplement (age ≥ 50) |

---

## Regulation: GlobalPayroll

### Cases

| Case | Type | Field | Value type | Time type |
|---|---|---|---|---|
| SocialSecurity | National | SocialSecurity Rate | Percent | Period |
| HealthInsurance | Company | HealthInsurance Rate | Percent | CalendarPeriod |
| Salary | Employee | Salary | Money | CalendarPeriod |
| EmploymentLevel | Employee | EmploymentLevel | Percent | Period |
| BirthDate | Employee | BirthDate | Date | Timeless |
| PerformanceBonus | Employee | PerformanceBonus | Money | Moment |

### Lookup: IncomeTax (progressive bracket)

| Bracket | Gross Income from | Rate |
|---|---|---|
| Bracket1 | 1 | 10 % |
| Bracket2 | 3 000 | 18 % |
| Bracket3 | 6 000 | 25 % |
| Bracket4 | 10 000 | 32 % |

### Wage Types

| # | Name | Expression summary | Collector |
|---|---|---|---|
| 100 | Base Salary | `Salary × EmploymentLevel` | Gross Income |
| 110 | Senior Supplement | `+5 % of Base Salary if age ≥ 50` | Gross Income |
| 120 | Performance Bonus | `PerformanceBonus` (Moment — single period only) | Gross Income |
| 200 | Income Tax | `Gross Income × progressive bracket rate` | Deductions |
| 210 | Social Security | `Gross Income × SocialSecurity Rate` | Deductions |
| 220 | Health Insurance | `Gross Income × HealthInsurance Rate` | Deductions |

### Collectors

| Collector | Contains |
|---|---|
| Gross Income | WT 100 + 110 + 120 |
| Deductions | WT 200 + 210 + 220 |

---

## Configuration

| Parameter | Value |
|---|---|
| SocialSecurity Rate | 10 % (national, from 2023-01-01) |
| HealthInsurance Rate | 5 % (company, from 2023-01-01) |

---

## Calculated Results

### January 2024 — Sarah Chen (full-time, with performance bonus)

| Wage Type | Calculation | Result |
|---|---|---|
| 100 Base Salary | 6 000 × 1.0 | 6 000.00 |
| 110 Senior Supplement | age 38 < 50 | 0.00 |
| 120 Performance Bonus | Moment Jan 2024 | 1 000.00 |
| **Gross Income** | | **7 000.00** |
| 200 Income Tax | 7 000 × 25 % (Bracket3) | 1 750.00 |
| 210 Social Security | 7 000 × 10 % | 700.00 |
| 220 Health Insurance | 7 000 × 5 % | 350.00 |
| **Deductions** | | **2 800.00** |
| **Net Pay** | | **4 200.00** |

### January 2024 — Carlos Rodriguez (60 % part-time, senior supplement)

| Wage Type | Calculation | Result |
|---|---|---|
| 100 Base Salary | 10 000 × 0.6 | 6 000.00 |
| 110 Senior Supplement | age 53 ≥ 50 → 6 000 × 5 % | 300.00 |
| 120 Performance Bonus | no bonus this period | 0.00 |
| **Gross Income** | | **6 300.00** |
| 200 Income Tax | 6 300 × 25 % (Bracket3) | 1 575.00 |
| 210 Social Security | 6 300 × 10 % | 630.00 |
| 220 Health Insurance | 6 300 × 5 % | 315.00 |
| **Deductions** | | **2 520.00** |
| **Net Pay** | | **3 780.00** |

### February 2024 — Sarah Chen (no bonus — Moment validation)

| Wage Type | Calculation | Result |
|---|---|---|
| 100 Base Salary | 6 000 × 1.0 | 6 000.00 |
| 110 Senior Supplement | age 38 < 50 | 0.00 |
| 120 Performance Bonus | Moment not in Feb — **must be 0** | 0.00 |
| **Gross Income** | | **6 000.00** |
| 200 Income Tax | 6 000 × 25 % (Bracket3) | 1 500.00 |
| 210 Social Security | 6 000 × 10 % | 600.00 |
| 220 Health Insurance | 6 000 × 5 % | 300.00 |
| **Deductions** | | **2 400.00** |
| **Net Pay** | | **3 600.00** |

> The February test is the critical verification: it confirms that the `Moment` time type correctly scopes the bonus to a single period and does not carry it forward.

---

## Files

| File | Purpose |
|---|---|
| `Prompt.md` | Natural language requirements used to generate this regulation |
| `Payroll.json` | Tenant, regulation, cases, wage types, payroll, payrun |
| `Payroll.Values.json` | Employee case values (salary, employment level, birth date, bonus) |
| `Payroll.Jobs.json` | Payrun job invocations for Jan–Mar 2024 |
| `Test.et.json` | Employee payroll test — Jan 2024 (bonus) and Feb 2024 (no bonus) |
| `Setup.pecmd` | Full setup: delete → import → set password → values → jobs |
| `Delete.pecmd` | Remove the GlobalTech tenant |
| `Import.pecmd` | Import regulation and payroll structure |
| `Import.Values.pecmd` | Import employee case values |
| `Import.Jobs.pecmd` | Import and run payrun jobs |
| `Test.pecmd` | Run employee payroll test |

---

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

## Web Application Login

| Field | Value |
|---|---|
| User | `admin@globaltech.com` |
| Password | `@ayroll3nginE` |

---

## Features Demonstrated

- **National case** — legislated rate that applies across all employees (SocialSecurity)
- **Company case** — employer-level setting (HealthInsurance)
- **Employee cases** — per-employee data: salary, employment level, birth date, performance bonus
- **Part-time factor** — EmploymentLevel scales the base salary via expression
- **Conditional wage type** — Senior Supplement activates only when employee age ≥ 50
- **Moment-based bonus** — PerformanceBonus recognised in exactly one pay period; Feb test proves it does not carry forward
- **Progressive lookup** — IncomeTax bracket table drives the income tax rate
- **Collector hierarchy** — Gross Income and Deductions aggregate wage type results
- **Two-period test** — `Test.et.json` covers Jan (with bonus) and Feb (without) to verify Moment scoping
