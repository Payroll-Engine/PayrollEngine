using PayrollEngine;
using PayrollEngine.Client;
using PayrollEngine.Client.Scripting.Function.Api;
using PayrollEngine.Serilog;
using Tasks = System.Threading.Tasks;

namespace ReportPayroll;

/// <summary>Scripting development tutorial program</summary>
internal class Program : ConsoleProgram<Program>
{
    private static ReportType currentReport = ReportType.EmployeeCaseValueEnd;
    private enum ReportType
    {
        EmployeeCaseValueBuild,
        EmployeeCaseValueEnd,
        CumulativeJournalEnd
    }

    /// <summary>The script configuration</summary>
    private ScriptConfiguration ScriptConfiguration =>
        Configuration.GetConfiguration<ScriptConfiguration>();

    /// <inheritdoc />
    protected override Tasks.Task RunAsync()
    {
        switch (currentReport)
        {
            case ReportType.EmployeeCaseValueBuild:
                EmployeeCaseValueReportBuild();
                break;
            case ReportType.EmployeeCaseValueEnd:
                EmployeeCaseValueReportEnd();
                break;
            case ReportType.CumulativeJournalEnd:
                CumulativeJournalReportEnd();
                break;
        }
        //CumulativeJournalReport();
        return Tasks.Task.CompletedTask;
    }

    private void EmployeeCaseValueReportBuild() =>
        new ReportBuildFunctionInvoker<EmployeeCaseValues.ReportBuildFunction>(
            HttpClient, ScriptConfiguration).Build("EmployeeCaseValues");

    private void EmployeeCaseValueReportEnd() =>
        new ReportEndFunctionInvoker<EmployeeCaseValues.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("EmployeeCaseValues");

    private void CumulativeJournalReportEnd() =>
        new ReportEndFunctionInvoker<CumulativeJournal.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("CumulativeJournal");

    /// <summary>Program entry point</summary>
    static async Tasks.Task Main()
    {
        // change the working report
        currentReport = ReportType.EmployeeCaseValueBuild;
        //currentReport = ReportType.EmployeeCaseValueEnd;
        //currentReport = ReportType.CumulativeJournalEnd;
        
        Log.SetLogger(new PayrollLog());
        using var program = new Program();
        await program.ExecuteAsync();
    }
}
