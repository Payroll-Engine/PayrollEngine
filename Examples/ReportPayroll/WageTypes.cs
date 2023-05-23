using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable once CheckNamespace
namespace ReportPayroll.WageTypes;

[WageTypeValueFunction(
    tenantIdentifier: "Payroll.Report",
    userIdentifier: "peter.schmid@foo.com",
    employeeIdentifier: "višnja.müller@foo.com",
    payrollName: "Payroll.Report",
    regulationName: "Payroll.Report")]
public class WageTypeValueFunction : PayrollEngine.Client.Scripting.Function.WageTypeValueFunction
{
    public WageTypeValueFunction(IWageTypeValueRuntime runtime) :
        base(runtime)
    {
    }

    public WageTypeValueFunction() :
        base(GetSourceFileName())
    {
    }

    [WageTypeValueScript(
        wageTypeNumber: "101")]
    public object Execute()
    {
        var values = GetCaseValues("Monatslohn", "EmploymentLevel");
        return values["Monatslohn"] * values["EmploymentLevel"];
    }
}