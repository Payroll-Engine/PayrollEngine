# StartPayroll.Yaml Tutorial

A step-by-step tutorial that builds a payroll regulation incrementally across
three layers, demonstrating the full regulation lifecycle from basic salary
calculation through derived insurance rules to a company-specific benefit.

This example is the reference implementation for the wiki tutorials
[Basic Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Basic-Payroll)
and [Advanced Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Advanced-Payroll).
All exchange files use **YAML** format. See [StartPayroll.Json](../StartPayroll.Json)
for the equivalent JSON version.

---

## Tutorial Structure

The tutorial proceeds in three setup steps, each adding one regulation layer:

```
Step 1: Basic     — StartRegulation     (Level 1)
Step 2: Insurance — InsuranceRegulation (Level 2, shared, derived from Step 1)
Step 3: Company   — CompanyRegulation   (Level 3, derived from Step 2)
Step 4: Report    — payslip report (EN/DE) on Step 3 results
Step 5: Test      — salary validation case test
```

Each step has its own setup and test command, allowing incremental exploration.

---

## Step 1 — Basic (`Basic.yaml`)

Minimal payroll: one employee, one salary wage type, two collectors.

### Regulation: StartRegulation

| Element | Name | Detail |
|:--|:--|:--|
| Case | `Salary` | Employee · CalendarPeriod · Money · range 500–25 000 |
| Build action | `Range(^:Salary, 500, 25000)` | Clamps input to valid range |
| Validate action | `Within(^:Salary, 500, 25000)` | Rejects out-of-range values |
| WT 100 | `Salary` | `CaseValue["Salary"]` → collector `Income` |
| Collector | `Income` | Gross income total |
| Collector | `Deduction` | `negated: true` — deductions total |

### Test — January 2023

| Employee | Salary | WT 100 | Income | Deduction |
|:--|--:|--:|--:|--:|
| Mario Nuñez | 5 000 | 5 000 | 5 000 | 0 |

---

## Step 2 — Insurance (`Insurance.yaml`)

Adds a shared insurance regulation with a range-based deduction lookup.

### Regulation: InsuranceRegulation

- `sharedRegulation: true` — reusable across tenants
- `baseRegulations: ["StartRegulation"]` — inherits all base wage types and cases
- Added at **Level 2** on `StartPayroll`

| Element | Name | Detail |
|:--|:--|:--|
| Lookup | `InsuranceRate` | Range lookup: salary < 3 000 → 30 · < 6 000 → 45 · ≥ 6 000 → 60 |
| WT 200 | `InsuranceRate` | `GetRangeLookup<decimal>("InsuranceRate", WageType[100])` → collector `Deduction` |

### Test — January + July 2023

| Period | Salary | WT 100 | WT 200 | Income | Deduction |
|:--|--:|--:|--:|--:|--:|
| Jan 2023 | 5 000 | 5 000 | 45 | 5 000 | −45 |
| Jul 2023 | 6 000 | 6 000 | 60 | 6 000 | −60 |

---

## Step 3 — Company (`Company.yaml`)

Adds a company regulation with a Moment-based benefit wage type.

### Regulation: CompanyRegulation

- `baseRegulations: ["InsuranceRegulation"]` — inherits Levels 1 + 2
- Added at **Level 3** on `StartPayroll`

| Element | Name | Detail |
|:--|:--|:--|
| Case | `Benefit` | Employee · Moment · Money |
| WT 100.1 | `Benefit` | `CaseValue["Benefit"]` → collector `Income` |

### Test — January 2023

Two benefit entries in January (Project A: 225, Project B: 250):

| Employee | WT 100 | WT 100.1 | WT 200 | Income | Deduction |
|:--|--:|--:|--:|--:|--:|
| Mario Nuñez | 5 000 | 475 | 45 | 5 475 | −45 |

---

## Step 4 — Report

Payslip report on the Step 3 results, available in German and English.

| File | Purpose |
|:--|:--|
| `Report.yaml` | Report definition imported into the regulation |
| `Report.German.frx` | German template |
| `Report.English.frx` | English template |
| `Report.Parameters.json` | `{ "PayrunJobName": "StartPayrunJob.Jan23" }` |

Output commands: `4 Report.Excel.pecmd` · `4 Report.Pdf.German.pecmd` · `4 Report.Pdf.English.pecmd` · `4 Report.XmlRaw.pecmd`

---

## Step 5 — Case Test (`Test.Salary.ct.yaml`)

Validates the `Salary` range guard (500–25 000):

| Test | Value | Expected |
|:--|--:|:--|
| `Employee.Salary.499.Test` | 499 | Issue `CaseInvalid` (400) |
| `Employee.Salary.500.Test` | 500 | Valid — value accepted |

---

## Files

| File | Purpose |
|:--|:--|
| `Basic.yaml` | Step 1: tenant, employee, StartRegulation, payroll, payrun |
| `Insurance.yaml` | Step 2: InsuranceRegulation + lookup (additive) |
| `Company.yaml` | Step 3: CompanyRegulation + Benefit case (additive) |
| `Report.yaml` | Step 4: payslip report definition |
| `Basic.Test.et.yaml` | Employee payroll test — Step 1 |
| `Insurance.Test.et.yaml` | Employee payroll test — Step 2 (Jan + Jul) |
| `Company.Test.et.yaml` | Employee payroll test — Step 3 |
| `Test.Salary.ct.yaml` | Case test — salary range validation |
| `Regulation.xlsx` | Regulation in Excel format |
| `Report.German.frx` / `Report.English.frx` | Report templates |
| `Report.Parameters.json` | Report parameters |

## Commands

```
# Full setup (all 3 layers + report)
Setup.pecmd

# Step-by-step setup
1 Basic.Setup.pecmd
2 Insurance.Setup.pecmd
3 Company.Setup.pecmd
4 Report.Setup.pecmd     # includes Company.Test.et.yaml /keeptest for report data

# Step-by-step tests
1 Basic.Test.pecmd
2 Insurance.Test.pecmd
3 Company.Test.pecmd
5 Test.Salary.pecmd      # case test

# Teardown
Delete.pecmd
```

## Web Application Login

| Field | Value |
|:--|:--|
| User | `lucy.smith@foo.com` |
| Password | `@ayroll3nginE` |

## See Also

- [StartPayroll.Json](../StartPayroll.Json) — identical tutorial in JSON format
- [Basic Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Basic-Payroll) — wiki tutorial (Steps 1–2)
- [Advanced Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Advanced-Payroll) — wiki tutorial (Step 3)
