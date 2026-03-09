# Payroll Engine Examples

## Commands
- `Setup.All.pecmd` - setup all examples
- `Delete.All.pecmd` - delete all examples
- `<Example>/Setup.pecmd` - setup example
- `<Example>/Delete.pecmd` - delete example

## Web Application Login
In the web application, `Lucy` has the `Supervisor` rights for **all** examples:
  - Name: `lucy.smith@foo.com`
  - Password: `@ayroll3nginE`

## Examples

### Action Payroll
- Custom `CaseValidate` action `CheckRegistrationNumber` — validates a structured registration number (REG-000.000.000)
- ISO 7064 check digit via `CheckDigit` scripting API
- Input mask `REG-000.000.000` on the `RegistrationNumber` field
- Localized action issues via `MyActions.Action` lookup (EN/DE)
- No-Code call site: `? CheckRegistrationNumber('RegistrationNumber', ^:RegistrationNumber)` in `validateActions`
- Case test with valid and invalid registration number test cases

### Case Definition Payroll
- All case value types with input attributes (mask, min/max, read-only, multi-line, step, datePicker)
- All case time types (Moment, Period, ClosedPeriod, CalendarPeriod, Timeless)
- Inline lists with alias mapping (display label ≠ stored value)
- Case Relations with build and validate expressions
- Three-level Case Slot hierarchy (SlotParent → SlotChild → SlotChildChild)
- No-Code build, validate and available actions
- Hidden cases, inactive override, cancellation type
- Custom Case scripts: `scripts/MyCaseChangeFunction.cs`, `scripts/MyCaseValidateFunction.cs`

### Extended Payroll
- Composite function pattern: business logic in `CompositeWageTypeValueFunction` class, injected via constructor
- `partial WageTypeValueFunction` registers the composite as a named property (`MyRegulation`)
- Wage type calls `MyRegulation.GetSalary()` directly from `valueExpression`
- Enables IDE support (IntelliSense, debugger) for regulation scripting
- Wiki tutorial: [Extended Functions](https://github.com/Payroll-Engine/PayrollEngine/wiki/Extended-Functions)
- Employee payroll test `Test.et.json`

### Report Payroll
Seven reports on one shared payroll dataset (3 employees, 7 payrun jobs Jan–Dec 2023 + Jan 2024):
- `CumulativeJournal` — scripted 12-month pivot table (wage types + collectors per employee)
- `EmployeeCaseValues` — build/start/end scripts, dynamic payroll + employee selection, lookup column
- `EmployeesXml` — XSLT transformation, XSD validation, no parameter form
- `Regulation` — multi-section with static relations (Regulations → WageTypes + Collectors)
- `RegulationsSimple` — inline `endExpression`, minimal query-only report
- `TenantsSimple` — static query, `attributeMode: Table`, template attachment extension
- `UsersSimple` — dynamic query injection at start phase via `SetQuery`

Read [more details](ReportPayroll/) about the example reports.

### Start Payroll
Step-by-step tutorial across 3 incremental regulation layers:
- **Step 1** (Basic): `StartRegulation` — Salary case, WT 100, Income + Deduction collectors, range guard (500–25 000)
- **Step 2** (Insurance): `InsuranceRegulation` (shared, derived) — adds range lookup `InsuranceRate`, WT 200
- **Step 3** (Company): `CompanyRegulation` (derived) — adds Moment-based Benefit case, WT 100.1
- **Step 4**: Payslip report (EN/DE, Excel/PDF/XML)
- **Step 5**: Case test for salary range validation
- Wiki tutorials: [Basic Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Basic-Payroll) and [Advanced Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Advanced-Payroll)
- Available in JSON (`StartPayroll.Json`) and YAML (`StartPayroll.Yaml`)

### Global Payroll
- Global, national and company cases across regulations
- Employment level scaling with part-time factor
- Age-conditional wage type (Senior Supplement)
- Moment-based performance bonus
- Progressive income tax via range lookup
- Two-period employee payroll test — January (with bonus) and February (Moment validation)
- **LLM reference example** — `Prompt.md` documents the natural language requirements used to generate this regulation; see [LLM-Assisted Development](https://payrollengine.org/Concepts/LLMAssistedDevelopment/)

### Multi-Country Payroll
- Multi-country regulation layers (DE, FR, NL)
- Shared base regulation (`ACME.Global`) reused in all country payrolls
- Global salary via `valueScope: Global` (single value read across payrolls)
- Split-country employee (60 % DE + 40 % FR) in two payrolls simultaneously
- Country-specific deduction wage types per regulation layer
- Employee payroll test with 5 result sets across 3 payrun jobs

### Retro Payroll
- Retroactive salary raise across multiple periods (positive deltas)
- Late bonus entry via `Moment` time type (auto-triggers retro for correct period)
- Retroactive part-time reduction (negative deltas — overpayment recovery)
- Cascading retro corrections (second correction on already-corrected period)
- Cluster design: `Legal` / `Retro` separation for base and delta wage types
- Self-contained payroll test `Payroll.pt.yaml`

### March Clause Payroll
- Q1 bonus check against the previous year's BBG (annual contribution ceiling) remainder
- Low-Code extension methods (`Scripts/MarchClauseFunctions.cs`) for pure BBG calculation
- Two employees: bonus below BBG remainder (no retro) vs. bonus exceeding remainder (retro in production)
- `ScheduleRetroPayrun()` production pattern documented in `valueExpression` comments
- `PreviousYearEarnings` as Timeless employee case; `BbgLimit` as Company case
- Self-contained payroll test `Payroll.mc.yaml`

### Forecast Payroll
- Two parallel what-if scenarios (`SalaryIncrease2026`, `BonusScenario2026`) over a 3-month planning horizon
- Forecast case data tagged at case-change level — invisible to production payruns
- `^^CaseField` resolves forecast-scoped override values automatically inside forecast jobs
- Condition guard `? ^^PlannedBonus > 0` suppresses optional wage type in production and unrelated scenarios (No-Code)
- `^$WageTypeName` cross-references in deduction and net wage types — identical in production and forecast runs
- Dedicated NetSalary wage type (WT 300) as single bottom-line comparison figure
- Fully No-Code regulation — no C# scripting required
- Self-contained payroll test `Payroll.fp.yaml`

### Part-Time Payroll
- Employment level scaling: `^^Salary * ^^EmploymentLevel` (No-Code)
- Overtime restricted to full-time employees via sequential `valueActions` conditions
- Case `availableActions` hides OvertimeHours from HR for part-time employees
- Case `buildActions`: `Range` clamps salary and employment level on input
- Retroactive employment level reduction (negative deltas — overpayment recovery)
- Fully No-Code regulation — `^$WageTypeName.RetroSum` accessor for retro corrections in `valueActions`
- Self-contained payroll test `Payroll.pt.yaml`

### Min Wage Payroll
- Automatic minimum wage top-up for hourly workers below the statutory minimum
- Year-versioned lookup `MinimumWage` — add a new key annually, no regulation change
- Intermediate wage type `MinWageBase` (WT 110) as reference only — excluded from collectors
- Compliance signal: `storeEmptyResults: true` → zero result = compliant
- Fully No-Code regulation

### Tax Table Payroll
- Bulk import of large national tax tables via `LookupTextImport`
- Range-based lookup for withholding tax deduction per employee
- Country-neutral fixed-width text file map (`TaxTable.Monthly.map.json`)

### Timesheet Payroll
Daily working hour recording with wage calculation for permanent and casual workers:
- `CaseObject` scripting: `Timesheet` base class + `[TimesheetPeriod]` attribute for early/regular/late hour phases
- Customer scripts in `Script/`: `MyTimesheet.cs` (subclass with 3 period slots + `WeekendRateFactor`) and `MyTimesheet.WageTypeValue.cs` (`MyTimesheetCalculator` + extensions)
- Calendar-driven periods; `Workdays` lookup for holidays and special days
- Casual vs. permanent worker wage calculation via `CasualRateFactor`
- Excel import: `Workdays.2025.xlsx` (lookup) and `WorkTimes.2025.Week8.xlsx` (case data)
- Reports: WorkTime (per employee/day) and Wage (per payrun job)
- Tests: Employee1 (permanent) and Employee2 (casual) — Week 2025/8

Read [more details](TimesheetPayroll/) about the timesheet payroll example.
