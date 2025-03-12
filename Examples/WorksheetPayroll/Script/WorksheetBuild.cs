using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace
public static class WorksheetBuild
{
    public static bool BuildWorksheet(this CaseBuildFunction function)
    {
        // start and end date from regular rate field
        function.UpdateStart(function.GetStart("RegularRate"));
        function.UpdateEnd(function.GetEnd("RegularRate"));

        // build info
        var duration = function.GetValue<decimal>("EarlyMorningDuration") +
                       function.GetValue<decimal>("RegularWorkTime") +
                       function.GetValue<decimal>("OvertimeLowDuration") +
                       function.GetValue<decimal>("OvertimeHighDuration");
        function.AddInfo("Total duration", $"{duration:0.##} hours");

        return true;
    }
}
