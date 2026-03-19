# ReportPayroll Example

A comprehensive report example collection for **Report.Tenant**, demonstrating
every major report pattern available in the engine: static queries, dynamic
parameters, scripted data assembly, XML transformation, multi-section relations,
and cluster-based access control.

Seven reports share one regulation and one set of payrun results, each illustrating
a distinct set of reporting concepts.

---

## Contents

- [Payroll Setup](#payroll-setup)
  - [Employees](#employees)
  - [Wage Types](#wage-types)
  - [Collectors](#collectors)
  - [Payrun Jobs](#payrun-jobs)
- [Report Overview](#report-overview)
- [Reports](#reports)
  - [Payslip](#payslip)
  - [CumulativeJournal](#cumulativejournal)
  - [EmployeeCaseValues](#employeecasevalues)
  - [EmployeesXml](#employeesxml)
  - [Regulation](#regulation)
  - [Tenants](#tenants)
  - [Users](#users)
- [FastReport Template Development](#fastreport-template-development)
- [Files](#files)
- [Commands](#commands)
- [Web Application Login](#web-application-login)
- [Features Demonstrated](#features-demonstrated)

---

## Payroll Setup

### Employees

| Employee | MonthlyWage | EmploymentLevel | BirthDate |
|:--|--:|--:|:--|
| Bachmann Christoph | 5 000 | 50 % (from 2025-04-24) | 1969-05-18 |
| Braunger Margarete | 7 000 | 80 % (from 2025-01-01) | 1969-05-18 |
| Frühling Andreas | 9 000 | 100 % (from 2025-01-01) | 1969-05-18 |
| Future Employee | — | — | — |

### Wage Types

| # | Name | Expression |
|:--|:--|:--|
| 101 | MonthlyWage | `WageTypes.cs` (script) |
| 200 | GrossWage | `Collector["GrossWage"].RoundTwentieth()` |
| 208 | AHV-Beitrag | `Collector["AHV Base"] × –1 × CaseValue["AHV AN"]` |
| 209 | ALV-Beitrag | `Collector["AHV Base"] × –1 × CaseValue["ALV AN"]` |
| 210 | UVG AN | `Collector["UVG Base"] × –1 × CaseValue["NBU Set"]` |
| 211 | KTG AN | `Collector["KTG Base"] × –1 × CaseValue["KTG Set"]` |
| 300 | Auszahlung | WT 200 + 208 + 209 + 210 + 211 |

### Collectors

`AHV Base` · `ALV Base` · `GrossWage` · `UVG Base` · `KTG Base`

### Payrun Jobs

| Job | Period | Status |
|:--|:--|:--|
| Report.PayrunJob.Jan25 | January 2025 | Complete |
| Report.PayrunJob.Feb25 | February 2025 | Complete |
| Report.PayrunJob.Mrz25 | March 2025 | Complete |
| Report.PayrunJob.Apr25 | April 2025 | Complete |
| Report.PayrunJob.Mai25 | May 2025 | Complete |
| Report.PayrunJob.Jun25 | June 2025 | Complete |
| Report.PayrunJob.Jul25 | July 2025 | Complete |
| Report.PayrunJob.Aug25 | August 2025 | Complete |
| Report.PayrunJob.Sep25 | September 2025 | Complete |
| Report.PayrunJob.Okt25 | October 2025 | Complete |
| Report.PayrunJob.Nov25 | November 2025 | Complete |
| Report.PayrunJob.Dez25 | December 2025 | Complete |
| Report.PayrunJob.Jan26 | January 2026 | Complete |

---

## Report Overview

| Report | Script | Clusters | Output |
|:--|:--|:--|:--|
| [Payslip](Payslip/) | `ReportEndFunction` | Month · Employee · Pay | Excel · PDF |
| [CumulativeJournal](CumulativeJournal/) | `ReportEndFunction` | Year · Employee · Pay | Excel · PDF |
| [EmployeeCaseValues](EmployeeCaseValues/) | Build + Start + End | Employee · CaseValue | Excel · PDF |
| [EmployeesXml](EmployeesXml/) | — | Employee · CaseValue · XML | XML |
| [Regulation](Regulation/) | — | Payroll · WageType · Collector | Excel · PDF |
| [Tenants](Tenants/) | — | Tenant | Excel · PDF |
| [Users](Users/) | Inline expression | User | Excel · PDF |

---

## Reports

### Payslip

Single-employee payslip with current-month values, retro column, and YTD accumulation.

| Feature | Detail |
|:--|:--|
| Script | `ReportEndFunction` — YTD accumulation loop + employee filter |
| Parameters | `PayslipYear` (Year, mandatory) · `PayslipMonth` (zero-padded integer, e.g. `03`, mandatory) · `EmployeeIdentifier` (optional, restricts to one employee) · `TenantId` (hidden) |
| Clusters | `Month` · `Employee` · `Pay` |
| Data assembly | Queries `GetConsolidatedWageTypeResults` and `GetConsolidatedCollectorResults` for each month 1..`PayslipMonth`; builds `Value` (current month), `YtdValue` (sum Jan–month), `RetroValue` (retro adjustment, 0 in this regulation) |
| Employee filter | `EmployeeIdentifier` parameter applied in script after query; empty = all employees |
| YTD expression | Computed column: `IIF(M1 IS NULL, 0, M1) + ... + IIF(Mn IS NULL, 0, Mn)` |
| Empty rows | Deleted with `DeleteRows("YtdValue = 0")` |
| Columns | `Name` (`WageTypeName - WageTypeNumber`) · `Amount` (current month) · `Retro` · `YTD` |
| Relations | `EmployeeWageTypeResults` and `EmployeeCollectorResults` related to `Employees` by `EmployeeId` |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) — A4 portrait, `Report.frx` |
| Output | Excel (`Report.Excel.pecmd`) · PDF (`Report.Pdf.pecmd`) |

---

### CumulativeJournal

Annual cumulative wage type and collector journal — one column per month,
one row per wage type / collector per employee.

| Feature | Detail |
|:--|:--|
| Script | `ReportEndFunction` — assembles pivot table across 12 months |
| Parameters | `JournalYear` (Year, mandatory, min 2000) · `Employees.Filter` (optional name filter) · `TenantId` (hidden) |
| Clusters | `Year` · `Employee` · `Pay` |
| Data assembly | Queries `GetConsolidatedWageTypeResults` and `GetConsolidatedCollectorResults` per employee per month; renames `Value` column to `M1`–`M12`; merges by `WageTypeNumber` / `CollectorName` |
| Total column | Computed expression: `IIF(M1 IS NULL, 0, M1) + ... + M12` |
| Empty rows | Deleted with `DeleteRows("Total = 0")` |
| Relations | `EmployeeWageTypeResults` and `EmployeeCollectorResults` related to `Employees` by `EmployeeId` |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) — both use same `Report.frx` |
| Output | Excel (`Report.Excel.pecmd`) · PDF (`Report.Pdf.pecmd`) |

---

### EmployeeCaseValues

Employee case value report with dynamic payroll and employee selection at build time.

| Feature | Detail |
|:--|:--|
| Scripts | `ReportBuildFunction` · `ReportStartFunction` · `ReportEndFunction` |
| Parameters | `PayrollId` (list from `QueryPayrolls`) · `AllEmployees` (Boolean, default true) · `EmployeeIdentifier` (hidden when AllEmployees=true) · `TenantId` (hidden) |
| Clusters | `Employee` · `CaseValue` |
| Build phase | Populates `PayrollId` list via `ExecuteInputListQuery`; conditionally shows `EmployeeIdentifier` when `AllEmployees = false` |
| Start phase | Sets `Employees.Filter` OData expression if a single employee is selected |
| End phase | Resolves `PayrollId` → queries employees → calls `ExecuteEmployeeTimeCaseValueQuery` for `MonthlyWage`, `EmploymentLevel`, `BirthDate`, `Location` (lookup column) |
| Lookup column | `Location` resolved from `Location` lookup for display value |
| Culture | Applied to case value query result (`UserCulture`) |
| Relations | `EmployeeCaseValues` relates `Employees` to `CaseValues` by `EmployeeId` |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) |
| Output | Excel · PDF |

---

### EmployeesXml

Employees exported as XML, transformed via XSLT and validated against an XSD schema.

| Feature | Detail |
|:--|:--|
| Script | None — query-only report |
| Parameters | `TenantId` (hidden) |
| Clusters | `Employee` · `CaseValue` · `XML` |
| Query | `QueryEmployees` → Employees table |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) — `contentType: application/xsl`, `contentFile: Employees.xsl`, `schemaFile: Employees.xsd` |
| XSL transform | `Employees.xsl` — transforms query result into structured XML output |
| XSD validation | `Employees.xsd` — validates transformed XML |
| No form | Report has no parameter form; runs directly |
| Output | XML (`Report.Xml.pecmd`) |

---

### Regulation

Multi-section regulation report listing wage types and collectors grouped under their regulation.

| Feature | Detail |
|:--|:--|
| Script | None — declarative query + relations |
| Parameters | `RegulationId` (RegulationId type, mandatory) · `Regulations.Filter` (`Id eq '$RegulationId$'`, hidden) · `TenantId` (hidden) |
| Clusters | `Payroll` · `WageType` · `Collector` |
| Queries | `QueryRegulations` · `QueryCollectors` · `QueryWageTypes` |
| Relations | `RegulationCollectors`: Regulations → Collectors by `RegulationId`; `RegulationWageTypes`: Regulations → WageTypes by `RegulationId` |
| Filter pattern | Hidden `Regulations.Filter` parameter injects OData filter from the selected `RegulationId` |
| Category | `Regulations` |
| Templates | `DefaultGerman` (de) only |
| Output | Excel · PDF |

---

### Tenants

Tenant list report demonstrating attribute mode and template attachment extensions.

| Feature | Detail |
|:--|:--|
| Script | None — static query |
| Parameters | None |
| Clusters | `Tenant` |
| Attribute mode | `attributeMode: "Table"` — tenant attributes exposed as table columns |
| Query | `QueryTenants` — static, no filter parameters |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) — `input.attachmentExtensions: ".frx"` allows `.frx` file attachment |
| Output | Excel · PDF |

---

### Users

User list report with dynamic query injection at start and cluster-based display control.

| Feature | Detail |
|:--|:--|
| Script | Inline `buildExpression` + `startExpression` |
| Build | `SetParameter("Users.TenantId", TenantId)` — injects tenant filter into query parameter |
| Start | `SetQuery("Users", "QueryUsers")` — assigns query dynamically; returns `null` to suppress default query |
| Parameters | None visible |
| Clusters | `User` |
| Templates | `DefaultGerman` (de) |
| Output | Excel · PDF |

---

## FastReport Template Development

See [FastReport.md](FastReport.md) for the full guide: initial template skeleton,
CI schema update, `ReportBuild` command reference, and which reports include a
`Report.Build.pecmd`.

---

## Files

```
ReportPayroll/
├── Payroll.json                  Tenant, employees, regulation, cases, wage types, payrun jobs
├── WageTypes.cs                  Wage type value script for WT 101 (MonthlyWage)
├── FastReport.md                 FastReport template development guide
├── Payslip/                      Single-employee payslip with current, retro, and YTD columns
├── CumulativeJournal/            Annual pivot journal — scripted data assembly
├── EmployeeCaseValues/           Employee case values — build/start/end scripts
├── EmployeesXml/                 XML export with XSLT transform and XSD validation
├── Regulation/                   Multi-section regulation detail report
├── Tenants/                      Static tenant list with attribute mode
├── Users/                        Dynamic query injection at start phase
├── Setup.pecmd                   Full setup: delete + import payroll + set password + import all reports
├── Import.pecmd                  Import Payroll.json only
├── Import.Reports.pecmd          Import all 7 report definitions
├── Import.Jobs.pecmd             Import payrun jobs (if separate from Payroll.json)
├── Delete.pecmd                  Remove the Report.Tenant
├── Rebuild.pecmd                 Rebuild regulation scripts
├── Script.WageTypes.pecmd        Publish WageTypes.cs wage type script
└── Report.EndQuery.pecmd         Run report via PayrollConsole (PDF, de-CH)
```

## Commands

```
# Full setup
Setup.pecmd

# Re-import reports only (after regulation changes)
Import.Reports.pecmd

# Publish wage type script after code change
Script.WageTypes.pecmd

# Teardown
Delete.pecmd
```

Each report subdirectory contains its own commands:

```
# Import report definition
<Report>/Import.pecmd

# Run as Excel
<Report>/Report.Excel.pecmd

# Run as PDF
<Report>/Report.Pdf.pecmd

# Publish report script (CumulativeJournal, EmployeeCaseValues, Payslip only)
<Report>/Script.pecmd
```

## Web Application Login

| Field | Value |
|:--|:--|
| User | `lucy.smith@foo.com` |
| Password | `@ayroll3nginE` |

---

## Features Demonstrated

- **Static query report** — `Tenants` and `EmployeesXml` deliver data entirely from declarative queries; no script phases required
- **Dynamic query injection** — `Users` assigns the API query at start via `SetQuery`; `buildExpression` injects the tenant filter parameter
- **`attributeMode: "Table"`** — `Tenants` flattens the tenant attribute dictionary into typed `DataTable` columns with an auto-generated DataRelation
- **Three-phase scripted report** — `EmployeeCaseValues` demonstrates Build (dropdown population, parameter visibility), Start (OData filter injection), and End (query execution, relation registration)
- **XSLT transformation** — `EmployeesXml` applies an XSL stylesheet and validates output against an XSD schema; no FRX template required
- **Multi-section relations** — `Regulation` links `Regulations` to `Collectors` and `WageTypes` via two static DataRelations declared in `Report.json`
- **Year-to-date aggregation** — `CumulativeJournal` and `Payslip` compute YTD in `ReportEndFunction` by querying one month at a time and renaming `Value` to `M1`–`M12`
- **Retro values in payslip** — `Payslip` calculates `RetroValue` by comparing consolidated results with original stored values across prior periods
- **Clean Lines design** — all FRX templates share a common layout system (navy header, teal card accent, gold underline, A4 portrait)
