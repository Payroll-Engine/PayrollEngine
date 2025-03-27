using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace TimesheetPayroll.Report.WorkTime;

[ReportBuildFunction(
    tenantIdentifier: "TimesheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "TimesheetRegulation")]
public class ReportBuildFunction : PayrollEngine.Client.Scripting.Function.ReportBuildFunction
{
    public ReportBuildFunction(IReportBuildRuntime runtime) :
        base(runtime)
    {
    }
    public ReportBuildFunction() :
        base(GetSourceFileName())
    {
    }
    [ReportBuildScript(
        reportName: "WorkTime",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\" }")]
    public bool? ReportBuildScript() =>
        TimesheetWorkTimeReport.Build(this);
}
