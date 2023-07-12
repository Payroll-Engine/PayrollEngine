using PayrollEngine;
using PayrollEngine.Client;
using PayrollEngine.Client.Scripting.Function.Api;
using PayrollEngine.Serilog;
using Tasks = System.Threading.Tasks;

namespace ReportPayroll;

/// <summary>Scripting development tutorial program</summary>
internal class Program : ConsoleProgram<Program>
{
    private static ReportType currentReport = ReportType.EmployeeCaseValues;
    private enum ReportType
    {
        EmployeeCaseValues,
        CumulativeJournal
    }

    /// <summary>The script configuration</summary>
    private ScriptConfiguration ScriptConfiguration =>
        Configuration.GetConfiguration<ScriptConfiguration>();

    /// <inheritdoc />
    protected override Tasks.Task RunAsync()
    {
        switch (currentReport)
        {
            case ReportType.EmployeeCaseValues:
                EmployeeCaseValueReport();
                break;
            case ReportType.CumulativeJournal:
                CumulativeJournalReport();
                break;
        }
        //CumulativeJournalReport();
        return Tasks.Task.CompletedTask;
    }

    private void EmployeeCaseValueReport() =>
        new ReportEndFunctionInvoker<EmployeeCaseValues.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("EmployeeCaseValues");

    private void CumulativeJournalReport() =>
        new ReportEndFunctionInvoker<CumulativeJournal.ReportEndFunction>(
            HttpClient, ScriptConfiguration).End("CumulativeJournal");

    /// <summary>Program entry point</summary>
    static async Tasks.Task Main()
    {
        // change the working report
        currentReport = ReportType.CumulativeJournal;
        
        Log.SetLogger(new PayrollLog());
        using var program = new Program();
        await program.ExecuteAsync();
    }
}
