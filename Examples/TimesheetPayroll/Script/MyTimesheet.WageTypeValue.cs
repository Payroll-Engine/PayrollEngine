using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace

public class MyTimesheetCalculator : TimesheetCalculator<MyTimesheet>
{
    protected override decimal CalcRegularWage(WageDay day, HourPeriod timesheetPeriod)
    {
        // regular wage
        var wage = base.CalcRegularWage(day, timesheetPeriod);

        // weekend factor
        if (day.Date.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday)
        {
            wage *= (1m + day.Timesheet.WeekendRateFactor);
        }
        return wage;
    }
}

/// <summary>Extensions for <see cref="WageTypeValueFunction"/></summary>
public static class WageTypeValueFunctionExtensions
{
    /// <summary>Calculate timesheet regular wage</summary>
    /// <param name="function">Wage type value function</param>
    public static decimal TimesheetRegularWage(this WageTypeValueFunction function) =>
        new MyTimesheetCalculator().RegularWage(function);

    /// <summary>Calculate timesheet period wage</summary>
    /// <param name="function">Wage type value function</param>
    /// <param name="periodPropertyName">Calc period property name</param>
    public static decimal TimesheetPeriodWage(this WageTypeValueFunction function, string periodPropertyName) =>
        new MyTimesheetCalculator().PeriodWage(function, periodPropertyName);
}
