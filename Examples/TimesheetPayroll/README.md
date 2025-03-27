# Payroll Engine Timesheet Example
This example shows how to create a payroll solution to record daily working hours.

The solution is based on a reusable timesheet module with the following features
- Support for different payroll wage periods (weekly, bi-weekly, monthly...) and weekdays
- Management of working days such as holidays, trade fair days
- Timesheet settings can be changed daily, even during the wage period
- Different daily hour rates with the share of the employee's salary
- Different wage calculations for permanent and temporary employees

The timesheet model is based on the `CaseObject` scripting class with payroll data mapped to C# classes.

## Calendar
The [Payroll Calendar](https://github.com/Payroll-Engine/PayrollEngine/wiki/Calendars) is used as the basis for determining the period and working days.
The `Workdays` lookup determines the holidays to exclude and the special days to include.

In the timesheet, the rates relevant for data entry and wage calculation are set. These settings are the [Time Data](https://github.com/Payroll-Engine/PayrollEngine/wiki/Time-Data), which allows the wage data to be checked on a daily basis.

## Timesheet Model

### Timesheet Scripts
The timesheet module is implemented in the following scripts.

| Name                   | Description                              | Function                 |
|:--|:--|:--|
| `Model.cs`             | Timesheet model types                    | All                      |
| `CaseBuild.cs`         | Handle timesheet cases input             | Case build               |
| `CaseValidate.cs`      | Validate the timesheet cases             | Case validate            |
| `ReportBuild.cs`       | Handle timesheet repots input            | Report build             |
| `ReportEnd.cs`         | Create timesheet reports                 | Report end               |
| `WageTypeValue.cs`     | Calculate timesheet wages                | Wage type value          |

### Timesheet (Company Case)
Based on the calendar, the timesheet keeps track of working hours and salary data:

| Field                  | Description                              | Value type               |
|:--|:--|:--|
| `StartTime`            | Regular period start time                | Hour                     |
| `EndTime`              | Regular period end time                  | Hour                     |
| `MinWorkTime`          | Minimum work time                        | Hour                     |
| `MaxWorkTime`          | Maximum work time                        | Hour                     |
| `BreakMin`             | Minimum break time                       | Minute                   |
| `BreakMax`             | Maximum break time <sup>1)</sup>         | Minute                   |
| `RegularRate`          | Regular hour rate                        | Money                    |
| `CasualRateFactor`     | Casual worker factor to the regular rate | Percent                  |

<sup>1)</sup> Disable break time with zero<br />

#### Timesheet Period
| Field                  | Description                              | Value type               |
|:--|:--|:--|
| `<Namespace>Duration`  | Period duration                          | Hour                     |
| `<Namespace>Factor`    | Period rate factor                       | Percent                  |

Timesheet periods without duration or factor are ignored.

Use the `TimesheetPeriodAttribute` to mark a timesheet period:
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
}
```

The attribute parameter `order` indicates the position of the period within the working day:
- early periods: `-1` first period before the regular work start time, `-2` (second period before...)
- late periods: `+1` first period after the regular work end time, `+2` (second period after...)

The `order 0` is used by the regular work and is not allowed for a timesheet period.

The `ns` attribute parameter specifies the namespace to be used as a prefix to the case field name.
 
### Employment (Employee Case - Administrator)
| Field                  | Description                              | Value type               |
|:--|:--|:--|
| `CasualWorker`         | Casual employee                          | Boolean                  |

### Work time (Employee Case - User or Employee Self-Service)
| Field                  | Description                              | Value type               |
|:--|:--|:--|
| `WorkTimeDate`         | Working day                              | Date                     |
| `WorkTimeStart`        | Start hour                               | Hour                     |
| `WorkTimeEnd`          | End hour                                 | Hour                     |
| `WorkTimeBreak`        | Break time                               | Minute                   |
| `WorkTimeHours`        | Working hours (calculated)               | Minute                   |


## Timesheet Payrun
The calculation of the wage data is done using the `TimesheetCalculator` class:
```csharp
public static class WageTypeValueFunctionExtensions
{
    public static decimal TimesheetRegularWage(this WageTypeValueFunction function) =>
        new TimesheetCalculator<MyTimesheet>().RegularWage(function);

    public static decimal TimesheetPeriodWage(this WageTypeValueFunction function, string periodPropertyName) =>
        new TimesheetCalculator<MyTimesheet>().PeriodWage(function, periodPropertyName);
}
```

In the payroll run, the period results of the timesheet are assigned to the wage types:

```json
"wageTypes": [
    {
        "wageTypeNumber": 110,
        "valueExpression": "this.TimesheetPeriodWage(\"EarlyPeriod\")"
    },
    {
        "wageTypeNumber": 120,
        "valueExpression": "this.TimesheetRegularWage()"
    },
    {
        "wageTypeNumber": 130,
        "valueExpression": "this.TimesheetPeriodWage(\"LatePeriodLow\")"
    },
    {
        "wageTypeNumber": 140,
        "valueExpression": "this.TimesheetPeriodWage(\"LatePeriodHigh\")"
    }
]
```

### Custom Wage Calculation
The following example shows a specialization of `Timesheet` with an additional wage factor for weekend days:
```csharp
public class MyTimesheet : Timesheet
{
    // case fields EarlyPeriodDuration and EarlyPeriodFactor
    [TimesheetPeriod(order: -1, ns: nameof(EarlyPeriod))]
    public TimesheetPeriod EarlyPeriod { get; } = new();

    // case fields LatePeriodLowDuration and LatePeriodLowFactor
    [TimesheetPeriod(order: 1, ns: nameof(LatePeriodLow))]
    public TimesheetPeriod LatePeriodLow { get; } = new();

    // case fields LatePeriodHighDuration and LatePeriodHighFactor
    [TimesheetPeriod(order: 2, ns: nameof(LatePeriodHigh))]
    public TimesheetPeriod LatePeriodHigh { get; } = new();

    // case field WeekendRateFactor
    public decimal WeekendRateFactor { get; set; }
}
```

The additional weekend rate factor is calculated in a specialization of `TimesheetCalculator`:
```csharp
public class MyTimesheetCalculator : TimesheetCalculator<MyTimesheet>
{
    protected override decimal CalcRegularWage(WageDay day, HourPeriod timesheetPeriod)
    {
        // regula wage
        var wage = base.CalcRegularWage(day, timesheetPeriod);

        // weekend factor
        if (day.Date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
        {
            wage *= (1m + day.Timesheet.WeekendRateFactor);
        }
        return wage;
    }
}
```

### Multiple Timesheets
To use multiple timesheets, the namespace can be defined with the `CaseObject` attribute:
```csharp
[CaseObject(ns: "Int")]
public class IntTimesheet : Timesheet
{
    // case fields IntEarlyPeriodDuration and IntEarlyPeriodFactor
    [TimesheetPeriod(order: -1, ns: nameof(EarlyPeriod))]
    public TimesheetPeriod EarlyPeriod { get; } = new();

    // case fields IntLatePeriodDuration and IntLatePeriodFactor
    [TimesheetPeriod(order: +1, ns: nameof(LatePeriod))]
    public TimesheetPeriod LatePeriod { get; } = new();
}

[CaseObject(ns: "Ext")]
public class ExtTimesheet : Timesheet
{
    // case fields ExtEarlyPeriodDuration and ExtEarlyPeriodFactor
    [TimesheetPeriod(order: -1, ns: nameof(EarlyPeriod))]
    public TimesheetPeriod EarlyPeriod { get; } = new();

    // case fields ExtLatePeriodDuration and ExtLatePeriodFactor
    [TimesheetPeriod(order: +1, ns: nameof(LatePeriod))]
    public TimesheetPeriod LatePeriod { get; } = new();
}
```

The names of the case fields must be adapted accordingly.

## Excel Import
In addition to Json, lookups and case values can also be imported from Excel files. In the example, the following Excel documents can be imported:

- Lookup `Workdays` with the holidays and special days in `Lookup/Workdays.2025.xlsx`
- Working time report in `Case.Data/WorkingTimes.2025.Week8.xlsx`

> The Excel documents have a special structure that must be respected.

## Timesheet Reports

- Work time report wit the parameter employee, payroll and workday
- Wage report with the parameters employee and payrun job

## Tests
- Employee1: Week 2025/8 payrun on non-casual worker
- Employee2: Week 2025/8 payrun on casual worker
