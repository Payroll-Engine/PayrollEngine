using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace
public static class WorkdayBuild
{
    public static bool BuildWorkday(this CaseBuildFunction function)
    {
        var valid = true;

        // work date
        var workday = function.GetValue<DateTime>("WorkdayDate");
        var workdayText = $"{workday:d}";
        function.UpdateStart(workday.Date);

        // duplicate
        var existingDay = function.GetRawCaseValue<DateTime?>("WorkdayDate", workday.Date);
        if (existingDay != null && existingDay == workday)
        {
            valid = false;
            function.AddInfo("Duplicate", workdayText);
        }

        // calendar work day
        if (!function.IsWorkDay(function.GetDerivedCalendar(), workday))
        {
            valid = false;
            function.AddInfo("Day off", $"{workday:dddd}");
        }

        // work period
        if (workday < function.PeriodStart)
        {
            valid = false;
            function.AddInfo("Before period", $"{function.PeriodStart:d}");
        }

        // regular work time
        var workMinHours = function.GetRawCaseValue<decimal>("RegularWorkTimeMin", workday);
        var workMaxHours = function.GetRawCaseValue<decimal>("RegularWorkTimeMax", workday);

        // hours
        var startHour = function.GetValue<decimal>("WorkdayStart");
        var endHour = function.GetValue<decimal>("WorkdayEnd");
        var breakMinutes = function.GetValue<decimal>("WorkdayBreak");
        if (endHour < startHour)
        {
            var newEndHour = startHour + workMinHours;
            function.SetValue("WorkdayEnd", Math.Min(24, newEndHour));
            endHour = newEndHour;
        }

        // break
        var breakMinMinutes = function.GetRawCaseValue<decimal>("BreakTimeMin", workday);
        var breakMaxMinutes = function.GetRawCaseValue<decimal>("BreakTimeMax", workday);
        if (breakMinMinutes == 0 && breakMaxMinutes == 0)
        {
            function.SetCaseFieldAttribute("WorkdayBreak", InputAttributes.Hidden, true);
        }
        else if (breakMinutes < breakMinMinutes)
        {
            function.SetValue("WorkdayBreak", breakMinMinutes);
            breakMinutes = breakMinMinutes;
        }
        else if (breakMaxMinutes > 0 && breakMinutes > breakMaxMinutes)
        {
            function.SetValue("WorkdayBreak", breakMaxMinutes);
            breakMinutes = breakMaxMinutes;
        }

        // working hours
        var workHours = endHour - startHour - (breakMinutes / 60m);
        // update hidden field value
        function.SetValue("WorkdayHours", workHours);
        if (workHours > 0)
        {
            function.AddInfo("Working time", $"{workHours:0.##} hours");
            if (workHours < workMinHours)
            {
                valid = false;
                function.AddInfo("Minimum time", $"{workMinHours:0.##} hours");
            }
            if (workMaxHours > 0 && workHours > workMaxHours)
            {
                valid = false;
                function.AddInfo("Maximum time", $"{workMaxHours:0.##} hours");
            }
            if (breakMinutes < breakMinMinutes)
            {            valid = false;

                function.AddInfo("Minimum break", $"{breakMinMinutes:0} minutes");
            }
            if (breakMaxMinutes > 0 && breakMinutes > breakMaxMinutes)
            {
                valid = false;
                function.AddInfo("Maximum break", $"{breakMaxMinutes:0} minutes");
            }
        }

        // change reason
        var reason = function.GetReason();
        if (string.IsNullOrWhiteSpace(reason) || reason.StartsWith("Working hours "))
        {
            function.SetReason($"Working hours {workdayText}");
        }

        // time step
        var step = function.GetRawCaseValue<int>("WorkTimeStep", workday);
        if (step >= 1 && step <= 30)
        {
            function.SetCaseFieldAttribute("WorkdayStart", InputAttributes.StepSize, step);
            function.SetCaseFieldAttribute("WorkdayEnd", InputAttributes.StepSize, step);
            function.SetCaseFieldAttribute("WorkdayBreak", InputAttributes.StepSize, step);
        }

        function.BuildValidity(valid);

        return true;
    }
}
