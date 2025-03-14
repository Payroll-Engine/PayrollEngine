using System;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace
public static class WorkdayValidate
{
    public static bool ValidateWorkday(this CaseValidateFunction function)
    {
        // work day
        var workday = function.GetValue<DateTime>("WorkdayDate");

        // duplicate
        var existingDay = function.GetRawCaseValue<DateTime?>("WorkdayDate", workday.Date);
        if (existingDay != null && existingDay == workday)
        {
            return function.AddIssue($"Workday {workday:d} already submitted.");
        }

        // calendar work day
        if (!function.IsWorkDay(function.GetDerivedCalendar(), workday))
        {
            return function.AddIssue($"{workday:dddd} is not a working day.");
        }

        // working hours
        var startHour = function.GetValue<decimal>("WorkdayStart");
        var endHour = function.GetValue<decimal>("WorkdayEnd");
        var breakMinutes = function.GetValue<decimal>("WorkdayBreak");
        var workHours = endHour - startHour - (breakMinutes / 60m);
        if (workHours <= 0)
        {
            return function.AddIssue("Missing working time.");
        }
        // update hidden field
        function.SetField("WorkdayHours", workHours, start: workday);

        // work time min
        var workMinHours = function.GetRawCaseValue<decimal>("RegularWorkTimeMin", workday);
        if (workMinHours > 0 && workHours < workMinHours)
        {
            return function.AddIssue($"Working time {workHours:0.##} is less than {workMinHours:0.##} hours.");
        }

        // work time max
        var workMaxHours = function.GetRawCaseValue<decimal>("RegularWorkTimeMax", workday);
        if (workMaxHours > 0 && workHours > workMaxHours)
        {
            return function.AddIssue($"Working time {workHours:0.##} is more than {workMaxHours:0.##} hours.");
        }

        // break time min
        var breakMinMinutes = function.GetRawCaseValue<decimal>("BreakTimeMin", workday);
        if (breakMinMinutes > 0 && breakMinutes < breakMinMinutes)
        {
            return function.AddIssue($"Break time {breakMinutes:0.##} is less than {breakMinMinutes:0.##} minutes.");
        }

        // break time max
        var breakMaxMinutes = function.GetRawCaseValue<decimal>("BreakTimeMax", workday);
        if (breakMaxMinutes > 0 && breakMinutes > breakMaxMinutes)
        {
            return function.AddIssue($"Break time {breakMinutes:0.##} is more than {breakMaxMinutes:0.##} minutes.");
        }

        return true;
    }
}
