# Payroll Engine Worksheet Example
This example shows how to create a payroll solution to record daily working hours.

There are different daily phases with their own wage factors:
| Phase                  | Description                              | Rate                           |
|:--|:--|:--|
| Early Morning          | Time from midnight to regular start      | Factor of regular/casual rate  |
| Regular                | Regular working time                     | Base rate with casual factor   |
| Overtime Low           | Time range after regular work            | Factor of regular/casual rate  |
| Overtime High          | Time after the low overtime to midnight  | Factor of regular/casual rate  |


- Early Morning
- Regular (base rate) and Regular Casual
- Overtime Low
- Overtime High

The [Payroll Calendar](https://github.com/Payroll-Engine/PayrollEngine/wiki/Calendars) is used as the basis for determining the period and working days.

In the worksheet, the rates relevant for data entry and wage calculation are set. These settings are the [Time Data](https://github.com/Payroll-Engine/PayrollEngine/wiki/Time-Data), which allows the wage data to be checked on a daily basis.

## Cases
### Worksheet
Based on the calendar, the worksheet keeps track of working hours and salary data:

| Field                  | Description                              | Type                     |
|:--|:--|:--|
| `RegularRate`          | Regular hour rate                        | Money                    |
| `CasualRateFactor`     | Casual worker rate factor                | Percent                  |
| `RegularWorkTime`      | Regular working time                     | Hour                     |
| `RegularWorkTimeMin`   | Minimum regular working time             | Hour                     |
| `RegularWorkTimeMax`   | Maximum regular working time             | Hour                     |
| `BreakTimeMin`         | Minimum break time                       | Minute                   |
| `BreakTimeMax`         | Maximum break time                       | Minute                   |
| `EarlyMorningDuration` | Duration of the early morning period     | Hour                     |
| `EarlyMorningFactor`   | Early morning rate factor                | Percent                  |
| `OvertimeLowDuration`  | Duration of the low overtime period      | Hour                     |
| `OvertimeLowFactor`    | Rate factor for the low overtime period  | Percent                  |
| `OvertimeHighDuration` | Duration of the high overtime period     | Hour                     |
| `OvertimeHighFactor`   | Rate factor for the high overtime period | Percent                  |
| `WorkTimeStep`         | Working time input step size             | Minute                   |

The following rules apply:

- The settings can be recorded on a daily basis.
- The break can be deactivated with zero values in `BreakTimeMin` and `BreakTimeMax`.
- The sum of `RegularWorkTime`, `EarlyMorningDuration`, `OvertimeLowDuration` and `OvertimeHighDuration` must be 24 hours.

### Casual worker
This case marks an employee as a casual worker and can be changed by the administrator.
The current value of this setting is used in the salary calculation.

### Working hours
This case allows for the recording of one working day.

| Field                  | Description                             | Type                     |
|:--|:--|:--|
| `WorkdayDate`          | Working day                             | Date                     |
| `WorkdayStart`         | Start hour                              | Hour                     |
| `WorkdayEnd`           | End hour                                | Hour                     |
| `WorkdayBreak`         | Break time                              | Minute                   |
| `WorkdayHours`         | Working hours (calculated)              | Minute                   |


## Reports

- Work time report: Select the employee > payroll > Workday
- Wage report: Select the employee > payrun job

## Payrun

| Item                  | Description                             | Type                     |
|:--|:--|:--|
| `EarlyMorningWage`    | Period total of the early morning wage  | Wage type #110           |
| `RegularWage`         | Period total of the regular wage        | Wage type #120           |
| `OvertimeLowWage`     | Period total of the low overtime wage   | Wage type #130           |
| `OvertimeHighWage`    | Period total of the high overtime wage  | Wage type #140           |
| `Income`              | Period total wage                       | Collector                |


## Scripts

- `WorksheetBuild.cs`: Build the Worksheet case
- `WorksheetValidate.cs`: Validate the Worksheet case
- `WorkdayBuild.cs`: Build the Workday case
- `WorkdayValidate.cs`: Validate the Workday case


## Tests
- Employee1: Week 2025/8 payrun on non-casual worker
- Employee2: Week 2025/8 payrun on casual worker
