using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace

/// <summary>Timesheet case validate</summary>
public static class TimesheetCase
{
    /// <summary>Validate the timesheet case</summary>
    public static bool Validate(CaseValidateFunction function) =>
        Validate<Timesheet>(function);

    /// <summary>Validate the timesheet case</summary>
    public static bool Validate<TTimesheet>(CaseValidateFunction function)
        where TTimesheet : Timesheet, new()
    {
        var workday = function.GetChangeCaseObject<TTimesheet>();

        // retro changes
        if (!function.AdminUser)
        {
            var start = function.GetStart(nameof(Timesheet.RegularRate));
            var period = function.GetCalendarPeriod();
            if (start.HasValue && period.IsBefore(start.Value))
            {
                function.AddIssue($"Timesheet change date {start.Value:d} is before calendar start {period.Start:d}");
                return true;
            }
        }

        // regular work time
        var workTime = workday.EndTime - workday.StartTime;
        if (workTime <= 0)
        {
            function.AddIssue("Missing timesheet regular duration.");
            return true;
        }

        if (workday.MaxWorkTime < workday.MinWorkTime)
        {
            function.AddIssue("Invalid working time maximum.");
            return true;
        }

        // break
        if (workday.BreakMax / 60 >= workTime)
        {
            function.AddIssue("Break time maximum must be less than the regular working time.");
            return true;
        }

        if (workday.BreakMax < workday.BreakMin)
        {
            function.AddIssue("Invalid break time maximum.");
            return true;
        }

        // time step
        if (workday.WorkTimeStep is < 1 or > 30)
        {
            function.AddIssue("Invalid working time step size.");
            return true;
        }

        if (60m % workday.WorkTimeStep != 0)
        {
            function.AddIssue("Working time step must be a part of 60 minutes.");
            return true;
        }

        // start/end date
        function.UpdateStart(function.GetStart("RegularRate"));
        function.UpdateEnd(function.GetEnd("RegularRate"));

        return true;
    }
}

/// <summary>Timesheet work time case validate</summary>
public static partial class TimesheetWorkTimeCase
{
    /// <summary>Validate the work time case</summary>
    public static bool Validate(CaseValidateFunction function) =>
        Validate<Timesheet, WorkTime>(function);

    /// <summary>Validate the work time case</summary>
    public static bool Validate<TTimesheet>(CaseValidateFunction function)
        where TTimesheet : Timesheet, new() =>
        Validate<TTimesheet, WorkTime>(function);

    /// <summary>Validate the work time case</summary>
    public static bool Validate<TTimesheet, TWorkTime>(CaseValidateFunction function)
        where TTimesheet : Timesheet, new()
        where TWorkTime : WorkTime, new()
    {
        // work time and timesheet data
        var workTime = function.GetChangeCaseObject<TWorkTime>();
        var timesheet = function.GetRawCaseObject<TTimesheet>(workTime.WorkTimeDate);

        // duplicate
        var workDate = function.GetRawCaseValue<DateTime?>(nameof(WorkTime.WorkTimeDate), workTime.WorkTimeDate);
        var duplicate = workDate != null && workDate.Value.Date == workTime.WorkTimeDate.Date;
        if (duplicate)
        {
            function.AddIssue($"Workday {workTime.WorkTimeDate:d} already submitted.");
            return true;
        }

        // day off by lookup
        var lookupDay = function.IsLookupWorkday(workTime.WorkTimeDate);
        if (lookupDay == false)
        {
            function.AddIssue($"{workTime.WorkTimeDate:d} is not a working day.");
            return true;
        }
        // day off by calendar weekday
        if (!function.IsCalendarWorkDay(workTime.WorkTimeDate) && lookupDay != true)
        {
            function.AddIssue($"{workTime:dddd} is not a working day.");
            return true;
        }

        // retro work time
        if (!function.AdminUser)
        {
            var period = function.GetCalendarPeriod();
            if (period.IsBefore(workTime.WorkTimeDate))
            {
                function.AddIssue($"Work time date {workTime.WorkTimeDate:d} is before calendar start {period.Start:d}");
                return true;
            }
        }

        // working hours
        if (workTime.WorkTimeHours <= 0)
        {
            function.AddIssue($"Missing working time (start={timesheet.StartTime}, end={timesheet.EndTime}).");
            return true;
        }
        // work time min
        if (timesheet.MinWorkTime > 0 && workTime.WorkTimeHours < timesheet.MinWorkTime)
        {
            function.AddIssue($"Working time {workTime.WorkTimeHours:0.##} is less than {timesheet.MinWorkTime:0.##} hours.");
            return true;
        }
        // work time max
        if (timesheet.MaxWorkTime > 0 && workTime.WorkTimeHours > timesheet.MaxWorkTime)
        {
            function.AddIssue($"Working time {workTime.WorkTimeHours:0.##} is more than {timesheet.MaxWorkTime:0.##} hours.");
            return true;
        }

        // break time min
        if (timesheet.BreakMin > 0 && workTime.WorkTimeBreak < timesheet.BreakMin)
        {
            function.AddIssue($"Break time {workTime.WorkTimeBreak:0.##} is less than {timesheet.BreakMin:0.##} minutes.");
            return true;
        }
        // break time max
        if (timesheet.BreakMax > 0 && workTime.WorkTimeBreak > timesheet.BreakMax)
        {
            function.AddIssue($"Break time {workTime.WorkTimeBreak:0.##} is more than {timesheet.BreakMax:0.##} minutes.");
            return true;
        }

        // start date
        function.UpdateStart(workTime.WorkTimeDate.Date);

        // apply changes
        function.SetChangeCaseObject(workTime);

        return true;
    }
}
