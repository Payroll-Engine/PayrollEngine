using PayrollEngine;
using PayrollEngine.Client;
using PayrollEngine.Client.Scripting.Function.Api;
using PayrollEngine.Serilog;
using Tasks = System.Threading.Tasks;

namespace ReportPayroll;

/// <summary>Scripting development tutorial program</summary>
internal class Program : ConsoleProgram<Program>
{
    /// <summary>The scripting configuration</summary>
    private ScriptingConfiguration ScriptingConfiguration =>
        Configuration.GetConfiguration<ScriptingConfiguration>();

    /// <inheritdoc />
    protected override Tasks.Task RunAsync()
    {
        EmployeeCaseValueReport();
        //CumulativeJournalReport();
        return Tasks.Task.CompletedTask;
    }

    private void EmployeeCaseValueReport()
    {
        new ReportEndFunctionInvoker<EmployeeCaseValues.ReportEndFunction>(
            HttpClient,
            ScriptingConfiguration).End("EmployeeCaseValues");
    }

    private void CumulativeJournalReport()
    {
        new ReportEndFunctionInvoker<CumulativeJournal.ReportEndFunction>(
            HttpClient,
            ScriptingConfiguration).End("CumulativeJournal");
    }

    /// <summary>Program entry point</summary>
    static async Tasks.Task Main()
    {
        Log.SetLogger(new PayrollLog());
        using var program = new Program();
        await program.ExecuteAsync();
    }
}
