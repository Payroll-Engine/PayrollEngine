using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable once CheckNamespace
namespace ReportPayroll.WageTypes;

[WageTypeValueFunction(
    tenantIdentifier: "Report.Tenant",
    userIdentifier: "lucy.smith@foo.com",
    employeeIdentifier: "višnja.müller@foo.com",
    payrollName: "Report.Payroll",
    regulationName: "Report.Regulation")]
// ReSharper disable once UnusedType.Global
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
        var values = GetCaseValues("MonthlyWage", "EmploymentLevel");
        return values["MonthlyWage"] * values["EmploymentLevel"];
    }
}