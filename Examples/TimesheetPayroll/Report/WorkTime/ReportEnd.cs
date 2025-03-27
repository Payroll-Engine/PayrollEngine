using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace TimesheetPayroll.Report.WorkTime;

[ReportEndFunction(
    tenantIdentifier: "TimesheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "TimesheetRegulation")]
public class ReportEndFunction : PayrollEngine.Client.Scripting.Function.ReportEndFunction
{
    public ReportEndFunction(IReportEndRuntime runtime) :
        base(runtime)
    {
    }
    public ReportEndFunction() :
        base(GetSourceFileName())
    {
    }
    [ReportEndScript(
        reportName: "WorkTime",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\", " +
                    "\"PayrollName\": \"TimesheetPayroll\", " +
                    "\"WorkDay\": \"2025-02-17T00:00:00.0Z\" }")]
    public bool? ReportEndScript() =>
        TimesheetWorkTimeReport.End(this);
}