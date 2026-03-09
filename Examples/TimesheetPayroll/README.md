# TimesheetPayroll Example

A daily working hour recording solution for **TimesheetTenant**, demonstrating
the `CaseObject` scripting pattern that maps payroll case fields to typed C# model
classes. The timesheet module is reusable — subclass `Timesheet` and
`TimesheetCalculator` to adapt it to any working-time regulation.

---

## Features

- Payroll calendars: weekly, bi-weekly, monthly
- Working day management via `Workdays` lookup (holidays, special days)
- Daily timesheet changes within a wage period
- Four configurable hour rate phases (early, regular, late-low, late-high)
- Different wage calculation for permanent and casual workers
- Weekend rate factor via `MyTimesheetCalculator` override
- Reports: work time report (per employee/day) and wage report (per payrun job)
- Excel import for lookup data and working time entries

---

## Timesheet Model

The timesheet module lives in the `Timesheet/` directory.

### Scripts

| File | Directory | Function type |
|:--|:--|:--|
| `Model.cs` | `Timesheet/` | All — model types shared across all functions |
| `CaseBuild.cs` | `Timesheet/` | CaseBuild — Timesheet company case |
| `CaseValidate.cs` | `Timesheet/` | CaseValidate — Timesheet company case |
| `CaseBuild.cs` | `Case/WorkTime/` | CaseBuild — WorkTime employee case |
| `CaseValidate.cs` | `Case/WorkTime/` | CaseValidate — WorkTime employee case |
| `CaseValidate.cs` | `Case/Timesheet/` | CaseValidate — Timesheet company case (case-level) |
| `ReportBuild.cs` | `Timesheet/` | ReportBuild — shared report build logic |
| `ReportEnd.cs` | `Timesheet/` | ReportEnd — shared report end logic |
| `WageTypeValue.cs` | `Timesheet/` | WageTypeValue — base wage calculation |
| `ReportBuild.cs` | `Report/WorkTime/` | ReportBuild — work time report |
| `ReportEnd.cs` | `Report/WorkTime/` | ReportEnd — work time report |
| `ReportBuild.cs` | `Report/Wage/` | ReportBuild — wage report |
| `ReportEnd.cs` | `Report/Wage/` | ReportEnd — wage report |

### Customer Scripts

The example customization lives in `Script/`:

| File | Purpose |
|:--|:--|
| `Script/MyTimesheet.cs` | Subclass of `Timesheet` — adds 3 period slots and `WeekendRateFactor` |
| `Script/MyTimesheet.WageTypeValue.cs` | `MyTimesheetCalculator` + `WageTypeValueFunctionExtensions` |

---

## Timesheet Case Fields

### Timesheet (Company Case)

| Field | Description | ValueType |
|:--|:--|:--|
| `StartTime` | Regular period start time | Hour |
| `EndTime` | Regular period end time | Hour |
| `MinWorkTime` | Minimum work time | Hour |
| `MaxWorkTime` | Maximum work time | Hour |
| `BreakMin` | Minimum break time | Minute |
| `BreakMax` | Maximum break time ¹ | Minute |
| `RegularRate` | Regular hour rate | Money |
| `CasualRateFactor` | Casual worker factor relative to regular rate | Percent |

¹ Set to zero to disable break time.

#### Timesheet Periods

Each period contributes a `<Namespace>Duration` (Hour) and `<Namespace>Factor`
(Percent) case field pair. Periods without duration or factor are ignored.

Periods are declared with `[TimesheetPeriod]` on the subclass:

```csharp
public class MyTimesheet : Timesheet
{
    // case fields EarlyPeriodDuration and EarlyPeriodFactor
    [TimesheetPeriod(order: -1, ns: nameof(EarlyPeriod))]
    public TimesheetPeriod EarlyPeriod { get; } = new();

    // case fields LatePeriodLowDuration and LatePeriodLowFactor
    [TimesheetPeriod(order: +1, ns: nameof(LatePeriodLow))]
    public TimesheetPeriod LatePeriodLow { get; } = new();

    // case fields LatePeriodHighDuration and LatePeriodHighFactor
    [TimesheetPeriod(order: +2, ns: nameof(LatePeriodHigh))]
    public TimesheetPeriod LatePeriodHigh { get; } = new();

    // case field WeekendRateFactor
    public decimal WeekendRateFactor { get; set; }
}
```

The `order` parameter positions the period in the working day:
- Early periods: `-1` (first before regular start), `-2` (second before), …
- Regular work: `0` — reserved, not allowed for custom periods
- Late periods: `+1` (first after regular end), `+2` (second after), …

The `ns` parameter is the prefix for the case field names.

### Employment (Employee Case — Administrator)

| Field | Description | ValueType |
|:--|:--|:--|
| `CasualWorker` | Marks employee as casual worker | Boolean |

### Work Time (Employee Case — User / Self-Service)

| Field | Description | ValueType |
|:--|:--|:--|
| `WorkTimeDate` | Working day | Date |
| `WorkTimeStart` | Start hour | Hour |
| `WorkTimeEnd` | End hour | Hour |
| `WorkTimeBreak` | Break time | Minute |
| `WorkTimeHours` | Working hours (calculated) | Minute |

---

## Calendar

The [Payroll Calendar](https://github.com/Payroll-Engine/PayrollEngine/wiki/Calendars)
determines the period and working days. The `Workdays` lookup defines holidays to
exclude and special days to include.

Timesheet settings store rates and constraints as
[Time Data](https://github.com/Payroll-Engine/PayrollEngine/wiki/Time-Data),
enabling daily wage data validation within the period.

---

## Wage Type Calculation

`Script/MyTimesheet.WageTypeValue.cs` defines `MyTimesheetCalculator` (overrides
weekend rate) and the extension methods:

```csharp
public static decimal TimesheetRegularWage(this WageTypeValueFunction function) =>
    new MyTimesheetCalculator().RegularWage(function);

public static decimal TimesheetPeriodWage(this WageTypeValueFunction function, string periodPropertyName) =>
    new MyTimesheetCalculator().PeriodWage(function, periodPropertyName);
```

Wage types call the extensions directly from `valueExpression`:

```json
"wageTypes": [
    { "wageTypeNumber": 110, "valueExpression": "this.TimesheetPeriodWage(\"EarlyPeriod\")" },
    { "wageTypeNumber": 120, "valueExpression": "this.TimesheetRegularWage()" },
    { "wageTypeNumber": 130, "valueExpression": "this.TimesheetPeriodWage(\"LatePeriodLow\")" },
    { "wageTypeNumber": 140, "valueExpression": "this.TimesheetPeriodWage(\"LatePeriodHigh\")" }
]
```

---

## Customization

### Weekend Rate Factor

`MyTimesheetCalculator` overrides `CalcRegularWage` to multiply the wage by
`WeekendRateFactor` on Saturday and Sunday:

```csharp
public class MyTimesheetCalculator : TimesheetCalculator<MyTimesheet>
{
    protected override decimal CalcRegularWage(WageDay day, HourPeriod timesheetPeriod)
    {
        var wage = base.CalcRegularWage(day, timesheetPeriod);
        if (day.Date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
        {
            wage *= (1m + day.Timesheet.WeekendRateFactor);
        }
        return wage;
    }
}
```

### Multiple Timesheets

Use `[CaseObject(ns: "...")]` to run two separate timesheets (e.g. internal +
external) with distinct case field name prefixes:

```csharp
[CaseObject(ns: "Int")]
public class IntTimesheet : Timesheet { ... }

[CaseObject(ns: "Ext")]
public class ExtTimesheet : Timesheet { ... }
```

Case field names are prefixed accordingly (`IntEarlyPeriodDuration`, etc.).

---

## Excel Import

Lookups and case data can be imported from Excel in addition to JSON:

| File | Import command | What it imports |
|:--|:--|:--|
| `Lookup/Workday/Workdays.2025.xlsx` | `RegulationExcelImport /backend` | `Workdays` lookup — holidays and special days for 2025 |
| `Case.Data/WorkTimes.2025.Week8.xlsx` | `CaseChangeExcelImport` | Employee work time entries for Week 8 / 2025 |

---

## Reports

| Report | Parameters | Output |
|:--|:--|:--|
| WorkTime | `EmployeeIdentifier`, `PayrollName`, `WorkDay` | Work time report per employee and day |
| Wage | `EmployeeIdentifier`, `PayrunJobName` | Wage report per payrun job |

Both reports are available as Excel, PDF, and JSON output.

---

## Tests

| Test | Employee | Scenario |
|:--|:--|:--|
| `Employee1.et.json` | višnja.müller@foo.com | Week 2025/8 — permanent worker |
| `Employee2.et.json` | leon.stark@foo.com | Week 2025/8 — casual worker |

---

## Files

| Path | Purpose |
|:--|:--|
| `Payroll.json` | Tenant, employees, regulation, payroll, payrun |
| `Timesheet/` | Core timesheet module scripts (Model, CaseBuild, CaseValidate, WageTypeValue, ReportBuild, ReportEnd) |
| `Script/MyTimesheet.cs` | Customer timesheet subclass with 3 period slots and weekend rate |
| `Script/MyTimesheet.WageTypeValue.cs` | `MyTimesheetCalculator` + `WageTypeValueFunctionExtensions` |
| `Case/` | Case definitions (company + employee) and case-level scripts |
| `Case.Data/` | Case data imports (JSON and Excel) |
| `Lookup/Workday/` | Workdays lookup (JSON and Excel for 2025) |
| `Report/WorkTime/` | Work time report definition and scripts |
| `Report/Wage/` | Wage report definition and scripts |
| `Test/` | Employee payroll tests (Employee1, Employee2) |

## Commands

```
# Full setup
Setup.pecmd

# Import Excel lookup (alternative to JSON)
Lookup/Workday/Import.Excel.pecmd

# Import Excel case data (alternative to JSON)
Case.Data/Import.Excel.pecmd

# Run tests
Test/Test.Employee1.pecmd
Test/Test.Employee2.pecmd

# Run reports
Report/WorkTime/Report.Excel.pecmd
Report/Wage/Report.Pdf.pecmd

# Teardown
Delete.pecmd
```

## Web Application Login

| User | Password | Role |
|:--|:--|:--|
| `lucy.smith@foo.com` | `@ayroll3nginE` | Tenant Administrator |
| `višnja.müller@foo.com` | `@ayroll3nginE` | Employee 1 (permanent) |
| `leon.stark@foo.com` | `@ayroll3nginE` | Employee 2 (casual) |
