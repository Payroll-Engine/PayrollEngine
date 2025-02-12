# Payroll Engine Examples

## Commands
- `Setup.All.cmd` - setup all examples
- `Delete.All.cmd` - delete all examples
- `<Example>/Setup.cmd` - setup example
- `<Example>/Delete.cmd` - delete example

## Web Application Login
In the web application, `Luci` has the `Supervisor` rights for **all** examples:
  - Name: `lucy.smith@foo.com`
  - Passwort: `@ayroll3nginE`

## Examples

### Action Payroll
- Custom script
- Custom case action `Scripts\MyAction.cs`
- Case input value mask `CHE-000.000.000`
- Case validation

### Case Definition Payroll
- All case value types
- All case time types
- Case Relations
- Case Slots
- Case Actions

### Derived Payroll
- Payroll with 3 regulations
- Override a base regulation case
- Add derived wage types
- Add sub wage types

### Extended Payroll
- Composite scripting function `Scripts\CompositeWageTypeValueFunction.cs`
- Wiki example [Composite Functions](https://github.com/Payroll-Engine/PayrollEngine/wiki/Extended-Functions#composite-function)

### Report Payroll
Report examples:
- `CumulativeJournal`
- `EmployeeCaseValues`
- `EmployeesXml`
- `Regulation`
- `RegulationsSimple`
- `TenantsSimple`
- `UsersSimple`

Read [more details](ReportPayroll/) about the example reports.

### Simple Payroll
- Payroll setup
- Case value and lookup import from Excel
- Regulation export
- Payruns

### Start Payroll
- Payroll with 3 regulations
- Add derived case
- Add derived wage types
- Add sub wage types
- Wiki examples [Basic Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Basic-Payroll) and [Advanced Payroll](https://github.com/Payroll-Engine/PayrollEngine/wiki/Advanced-Payroll)

### Week Simple Payroll
- Payroll with weekly wage periods, calendar period `Week`
