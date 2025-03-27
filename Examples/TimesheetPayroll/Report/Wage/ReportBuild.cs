using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace TimesheetPayroll.Report.Wage;

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
        reportName: "Wage",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\", " +
                    "\"PayrunJobName\": \"TimesheetPayrunJob.Week14.2025\" }")]
    public bool? ReportBuildScript() =>
        TimesheetWageReport.Build(this);
}
