using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

namespace TimesheetPayroll.Case.WorkTime;

[CaseValidateFunction(
    tenantIdentifier: "TimesheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    employeeIdentifier: "višnja.müller@foo.com",
    payrollName: "TimesheetPayroll",
    regulationName: "TimesheetRegulation")]
public class CaseValidateFunction : PayrollEngine.Client.Scripting.Function.CaseValidateFunction
{
    public CaseValidateFunction(ICaseValidateRuntime runtime) :
        base(runtime)
    {
    }
    public CaseValidateFunction() :
        base(GetSourceFileName())
    {
    }
    [CaseValidateScript(caseName: "WorkTime")]
    public bool? CaseValidateScript() =>
        TimesheetWorkTimeCase.Validate<MyTimesheet>(this);
}
