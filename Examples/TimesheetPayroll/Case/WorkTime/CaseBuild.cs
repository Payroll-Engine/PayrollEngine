using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

namespace TimesheetPayroll.Case.WorkTime;

[CaseBuildFunction(
    tenantIdentifier: "TimesheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    employeeIdentifier: "višnja.müller@foo.com",
    payrollName: "TimesheetPayroll",
    regulationName: "TimesheetRegulation")]
public class CaseBuildFunction : PayrollEngine.Client.Scripting.Function.CaseBuildFunction
{
    public CaseBuildFunction(ICaseBuildRuntime runtime) :
        base(runtime)
    {
    }
    public CaseBuildFunction() :
        base(GetSourceFileName())
    {
    }
    [CaseBuildScript(caseName: "WorkTime")]
    public bool? CaseBuildScript() =>
        TimesheetWorkTimeCase.Build<MyTimesheet>(this);
}
