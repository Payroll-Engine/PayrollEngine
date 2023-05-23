using System.Data;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

namespace PayrollEngine.Client.Tutorial.ScriptingDevelopment;

[ReportEndFunction(
    tenantIdentifier: "ReportTest",
    userIdentifier: "peter.schmid@foo.com",
    regulationName: "ReportTest")]
public class WageTypeReportEndFunction : Scripting.Function.ReportEndFunction
{
    public WageTypeReportEndFunction(IReportEndRuntime runtime) :
        base(runtime)
    {
    }

    [ReportEndScript(
        reportName: "EmployeesReport",
        language: Scripting.Language.German)]
    public object ReportEndScript()
    {
        // employees
        var employees = Tables["Employees"];
        if (employees == null)
        {
            throw new ScriptException("Missing employees");
        }

        // add employee type column
        employees.InsertColumn<int>(0, "Type");
        foreach (var employee in employees.AsEnumerable())
        {
            var type = employee.GetAttribute<int>("Attributes", "EmployeeType");
            employee["Type"] = type;
        }

        return default;
    }
}

