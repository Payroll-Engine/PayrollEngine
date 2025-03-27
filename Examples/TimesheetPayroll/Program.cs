using PayrollEngine;
using PayrollEngine.Client;
using PayrollEngine.Serilog;
using PayrollEngine.Client.Scripting.Function.Api;
using TimesheetPayroll.Case.WorkTime;
using Tasks = System.Threading.Tasks;

namespace TimesheetPayroll;

/// <summary>Scripting development tutorial program</summary>
internal class Program : ConsoleProgram<Program>
{
    // change the working command
    private static readonly Command command = Command.WorkTimeCaseValidate;

    private enum Command
    {
        // case timesheet
        TimesheetCaseValidate,

        // case work time
        WorkTimeCaseBuild,
        WorkTimeCaseValidate,

        // report work time
        WorkTimeReportBuild,
        WorkTimeReportEnd,

        // report wage
        WageReportBuild,
        WageReportEnd
    }

    /// <summary>The script configuration</summary>
    private ScriptConfiguration ScriptConfiguration =>
        Configuration.GetConfiguration<ScriptConfiguration>();

    /// <inheritdoc />
    protected override Tasks.Task RunAsync()
    {
        switch (command)
        {
            // case
            case Command.TimesheetCaseValidate:
                TimesheetCaseValidate();
                break;

            case Command.WorkTimeCaseBuild:
                WorkTimeCaseBuild();
                break;
            case Command.WorkTimeCaseValidate:
                WorkTimeCaseValidate();
                break;

            // report
            case Command.WorkTimeReportBuild:
                WorkTimeReportBuild();
                break;
            case Command.WorkTimeReportEnd:
                WorkTimeReportEnd();
                break;

            case Command.WageReportBuild:
                WageReportBuild();
                break;
            case Command.WageReportEnd:
                WageReportEnd();
                break;
        }
        return Tasks.Task.CompletedTask;
    }

    #region Case Timesheet

    private void TimesheetCaseValidate() =>
        new CaseValidateFunctionInvoker<Case.Timesheet.CaseValidateFunction>(
            HttpClient, ScriptConfiguration).Validate("Timesheet");

    #endregion

    #region Case Workday

    private void WorkTimeCaseBuild() =>
        new CaseBuildFunctionInvoker<CaseBuildFunction>(
            HttpClient, ScriptConfiguration).Build("WorkTime");

    private void WorkTimeCaseValidate() =>
        new CaseValidateFunctionInvoker<CaseValidateFunction>(
            HttpClient, ScriptConfiguration).Validate("WorkTime");

    #endregion

    #region Report Work Time

    private void WorkTimeReportBuild() =>
        new ReportBuildFunctionInvoker<Report.WorkTime.ReportBuildFunction>(
            HttpClient, ScriptConfiguration).Build("WorkTime");

    private void WorkTimeReportEnd() =>
        new ReportEndFunctionInvoker<Report.WorkTime.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("WorkTime");

    #endregion

    #region Report Wage

    private void WageReportBuild() =>
        new ReportBuildFunctionInvoker<Report.Wage.ReportBuildFunction>(
            HttpClient, ScriptConfiguration).Build("Wage");

    private void WageReportEnd() =>
        new ReportEndFunctionInvoker<Report.Wage.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("Wage");

    #endregion

    /// <summary>Program entry point</summary>
    static async Tasks.Task Main()
    {
        Log.SetLogger(new PayrollLog());
        using var program = new Program();
        await program.ExecuteAsync();
    }
}
