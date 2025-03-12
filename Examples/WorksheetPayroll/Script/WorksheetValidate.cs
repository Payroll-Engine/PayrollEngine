using System;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace
public static class WorksheetValidate
{
    public static bool ValidateWorksheet(this CaseValidateFunction function)
    {
        // regular
        var regularWorkHours = function.GetValue<decimal>("RegularWorkTime");
        if (regularWorkHours == 0)
        {
            return function.AddIssue("Missing worksheet regular duration.");
        }
        if (function.GetValue<decimal>("RegularWorkTimeMax") <
            function.GetValue<decimal>("RegularWorkTimeMin"))
        {
            return function.AddIssue("Invalid Working time maximum.");
        }

        // break
        var breakMaxMinutes = function.GetValue<decimal>("BreakTimeMax");
        if (breakMaxMinutes / 60 >= regularWorkHours)
        {
            return function.AddIssue("Break time maximum must be less than the regular working time.");
        }
        if (breakMaxMinutes < function.GetValue<decimal>("BreakTimeMin"))
        {
            return function.AddIssue("Invalid break time maximum.");
        }

        // duration
        var duration = function.GetValue<decimal>("EarlyMorningDuration") +
                       regularWorkHours +
                       function.GetValue<decimal>("OvertimeLowDuration") +
                       function.GetValue<decimal>("OvertimeHighDuration");
        // total duration must be 24 hours
        if (Math.Abs(24m - duration) > 0.001m)
        {
            return function.AddIssue($"Total duration is not 24 hours: {duration:0.##}.");
        }

        // time step
        var timeStepMinutes = function.GetValue<int>("WorkTimeStep");
        if (timeStepMinutes < 1 || timeStepMinutes > 30)
        {
            return function.AddIssue("Invalid working time step size.");
        }
        if (60m % timeStepMinutes != 0)
        {
            return function.AddIssue("Working time step must be a part of 60 minutes.");
        }

        return true;
    }
}
