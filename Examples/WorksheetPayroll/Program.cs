using PayrollEngine;
using PayrollEngine.Client;
using PayrollEngine.Serilog;
using PayrollEngine.Client.Scripting.Function.Api;
using Tasks = System.Threading.Tasks;

namespace WorksheetPayroll;

/// <summary>Scripting development tutorial program</summary>
internal class Program : ConsoleProgram<Program>
{
    private static ReportType currentReport = ReportType.WorkTimeBuild;
    private enum ReportType
    {
        WorkTimeBuild,
        WorkTimeEnd,
        WageBuild,
        WageEnd
    }

    /// <summary>The script configuration</summary>
    private ScriptConfiguration ScriptConfiguration =>
        Configuration.GetConfiguration<ScriptConfiguration>();

    /// <inheritdoc />
    protected override Tasks.Task RunAsync()
    {
        switch (currentReport)
        {
            case ReportType.WorkTimeBuild:
                WorkTimeReportBuild();
                break;
            case ReportType.WorkTimeEnd:
                WorkTimeReportEnd();
                break;
            case ReportType.WageBuild:
                WageReportBuild();
                break;
            case ReportType.WageEnd:
                WageReportEnd();
                break;
        }
        return Tasks.Task.CompletedTask;
    }

    private void WorkTimeReportBuild() =>
        new ReportBuildFunctionInvoker<Report.WorkTime.ReportBuildFunction>(
            HttpClient, ScriptConfiguration).Build("WorkTime");

    private void WorkTimeReportEnd() =>
        new ReportEndFunctionInvoker<Report.WorkTime.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("WorkTime");

    private void WageReportBuild() =>
        new ReportBuildFunctionInvoker<Report.Wage.ReportBuildFunction>(
            HttpClient, ScriptConfiguration).Build("Wage");

    private void WageReportEnd() =>
        new ReportEndFunctionInvoker<Report.Wage.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("Wage");

    /// <summary>Program entry point</summary>
    static async Tasks.Task Main()
    {
        // change the working report
        //currentReport = ReportType.WorkTimeBuild;
        currentReport = ReportType.WorkTimeEnd;
        //currentReport = ReportType.WageBuild;
        //currentReport = ReportType.WageEnd;

        Log.SetLogger(new PayrollLog());
        using var program = new Program();
        await program.ExecuteAsync();
    }
}
