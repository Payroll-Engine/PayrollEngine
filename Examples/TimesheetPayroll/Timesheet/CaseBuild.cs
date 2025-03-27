using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace

/// <summary>Timesheet work time case build</summary>
public static partial class TimesheetWorkTimeCase
{
    /// <summary>Build the work time case</summary>
    public static bool Build(CaseBuildFunction function) =>
        Build<Timesheet, WorkTime>(function);

    /// <summary>Build th e work time case</summary>
    public static bool Build<TTimesheet>(CaseBuildFunction function)
        where TTimesheet : Timesheet, new() =>
        Build<TTimesheet, WorkTime>(function);

    /// <summary>Build the work time case</summary>
    public static bool Build<TTimesheet, TWorkTime>(CaseBuildFunction function)
        where TTimesheet : Timesheet, new()
        where TWorkTime : WorkTime, new()
    {
        var valid = true;

        // work time and timesheet data
        var workTime = function.GetChangeCaseObject<TWorkTime>();
        var timesheet = function.GetRawCaseObject<TTimesheet>(workTime.WorkTimeDate);

        // ensure same start date
        function.UpdateStart(workTime.WorkTimeDate.Date);

        // duplicate workday
        var workdayText = $"{workTime.WorkTimeDate:d}";

        // duplicate
        var workDate = function.GetRawCaseValue<DateTime?>(nameof(WorkTime.WorkTimeDate), workTime.WorkTimeDate);
        var duplicate = workDate != null && workDate.Value.Date == workTime.WorkTimeDate.Date;
        if (duplicate)
        {
            valid = false;
            function.AddInfo("Duplicate", workdayText);
        }

        // day off
        var lookupDay = function.IsLookupWorkday(workTime.WorkTimeDate);
        if (lookupDay == false)
        {
            // day off by lookup
            valid = false;
            function.AddInfo("Day off", $"{workTime.WorkTimeDate:d}");
        }
        else if (!function.IsCalendarWorkDay(workTime.WorkTimeDate) && lookupDay != true)
        {
            // day off by calendar weekday
            // set the lookup workday to true to allow calendar exceptions
            valid = false;
            function.AddInfo("Day off", $"{workTime.WorkTimeDate:dddd}");
        }

        // out of work period
        if (!function.AdminUser)
        {
            var period = function.GetCalendarPeriod();
            if (period.IsWithin(workTime.WorkTimeDate))
            {
                function.AddInfo("Out of work period", $"{period}");
            }
        }

        // work period
        if (workTime.WorkTimeEnd < workTime.WorkTimeStart)
        {
            workTime.WorkTimeEnd = workTime.WorkTimeStart + timesheet.MinWorkTime;
        }

        // work time
        if (workTime.WorkTimeHours > 0)
        {
            function.AddInfo("Working time", $"{workTime.WorkTimeHours:0.##} hours");
            // work time min
            if (workTime.WorkTimeHours < timesheet.MinWorkTime)
            {
                valid = false;
                function.AddInfo("Minimum time", $"{timesheet.MinWorkTime:0.##} hours");
            }
            // work time max
            if (timesheet.MaxWorkTime > 0 && workTime.WorkTimeHours > timesheet.MaxWorkTime)
            {
                valid = false;
                function.AddInfo("Maximum time", $"{timesheet.MaxWorkTime:0.##} hours");
            }
        }

        // break time
        if (!timesheet.BreakEnabled())
        {
            // no break time
            function.HideCaseField(workTime.GetCaseFieldName(nameof(WorkTime.WorkTimeBreak)));
        }
        else if (workTime.WorkTimeBreak < timesheet.BreakMin)
        {
            // break time min
            workTime.WorkTimeBreak = timesheet.BreakMin;
        }
        else if (workTime.WorkTimeBreak > 0 && workTime.WorkTimeBreak > timesheet.BreakMax)
        {
            // break time max
            workTime.WorkTimeBreak = timesheet.BreakMax;
        }

        // default change reason
        var reason = function.GetReason();
        if (string.IsNullOrWhiteSpace(reason) || reason.StartsWith("Work time "))
        {
            function.SetReason($"Work time {workdayText}");
        }

        // time step
        var step = timesheet.WorkTimeStep;
        if (step is >= 1 and <= 30)
        {
            function.SetCaseFieldAttribute(workTime.GetCaseFieldName(nameof(WorkTime.WorkTimeStart)), InputAttributes.StepSize, step);
            function.SetCaseFieldAttribute(workTime.GetCaseFieldName(nameof(WorkTime.WorkTimeEnd)), InputAttributes.StepSize, step);
            function.SetCaseFieldAttribute(workTime.GetCaseFieldName(nameof(WorkTime.WorkTimeBreak)), InputAttributes.StepSize, step);
        }

        // apply changes
        function.SetChangeCaseObject(workTime);

        // validation
        function.BuildValidity(valid);

        return true;
    }
}
