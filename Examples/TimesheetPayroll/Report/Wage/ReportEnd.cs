using System.Diagnostics.CodeAnalysis;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace TimesheetPayroll.Report.Wage;

[ReportEndFunction(
    tenantIdentifier: "TimesheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "TimesheetRegulation")]
[SuppressMessage("ReSharper", "CommentTypo")]
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
        reportName: "Wage",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\", " +
                    "\"PayrunJobName\": \"TimesheetPayrunJob.Week14.2025\" }")]
    public bool? ReportEndScript() =>
        TimesheetWageReport.End(this);
}