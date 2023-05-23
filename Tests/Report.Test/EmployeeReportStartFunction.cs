using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

namespace PayrollEngine.Client.Tutorial.ScriptingDevelopment;

[ReportStartFunction(
    tenantIdentifier: "ReportTest",
    userIdentifier: "peter.schmid@foo.com",
    regulationName: "ReportTest")]
public class WageTypeReportStartFunction : Scripting.Function.ReportStartFunction
{
    public WageTypeReportStartFunction(IReportStartRuntime runtime) :
        base(runtime)
    {
    }

    [ReportStartScript(
        reportName: "EmployeesReport",
        language: Scripting.Language.German)]
    public object Execute()
    {
        // employee type
        var typeArgument = GetParameter("EmployeeType");
        if (!string.IsNullOrWhiteSpace(typeArgument) && int.TryParse(typeArgument, out var employeeType))
        {
            SetParameter<string>("Employees.Filter", new Equals("EmployeeType".ToNumericAttributeField(), employeeType));
        }
        return null;
    }
}
