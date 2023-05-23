using System.Collections.Generic;
using PayrollEngine.Client.Scripting.Runtime;
using System.Data;
using System.Linq;
using System.Text.Json;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;
using PayrollEngine.Client.Scripting.Report;

// ReSharper disable once CheckNamespace
namespace ReportPayroll.EmployeeCaseValues;

[ReportBuildFunction(
    tenantIdentifier: "Payroll.Report",
    userIdentifier: "peter.schmid@foo.com",
    regulationName: "Payroll.Report")]
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
        reportName: "EmployeeCaseValues",
        language: Language.German)]
    public object ReportBuildScript()
    {
        var allParameter = "AllEmployees";
        var employeeParameter = "EmployeeIdentifier";

        // all employees
        var allEmployees = GetParameter(allParameter, true);
        if (!allEmployees)
        {
            var employees = ExecuteQuery("QueryEmployees",
                new QueryParameters()
                    .Parameter(nameof(TenantId), TenantId));
            if (employees.Rows.Count == 0)
            {
                return null;
            }

            // setup list
            var list = new List<string>();
            var listValues = new List<string>();
            foreach (var employee in employees.AsEnumerable())
            {
                list.Add($"{employee["FirstName"]} {employee["LastName"]}");
                listValues.Add(employee["Identifier"].ToString());
            }
            SetParameterAttribute(employeeParameter, "input.list", 
                JsonSerializer.Serialize(list));
            SetParameterAttribute(employeeParameter, "input.listValues",
                JsonSerializer.Serialize(listValues));

            // preselect the first employee
            if (listValues.Count > 0)
            {
                SetParameterAttribute(employeeParameter, "input.listSelection", listValues.First());
            }
        }

        // employee selection
        SetParameterAttribute(employeeParameter, "input.hidden", allEmployees);

        return null;
    }
}

[ReportStartFunction(
    tenantIdentifier: "Payroll.Report",
    userIdentifier: "peter.schmid@foo.com",
    regulationName: "Payroll.Report")]
public class ReportStartFunction : PayrollEngine.Client.Scripting.Function.ReportStartFunction
{
    public ReportStartFunction(IReportStartRuntime runtime) :
        base(runtime)
    {
    }

    public ReportStartFunction() :
        base(GetSourceFileName())
    {
    }

    [ReportStartScript(
        reportName: "EmployeeCaseValues",
        language: Language.German)]
    public object ReportStartScript()
    {
        if (HasParameter("EmployeeIdentifier"))
        {
            SetParameter("Employees.Filter", new EqualIdentifier(GetParameter("EmployeeIdentifier")).Expression);
        }

        return null;
    }
}

[ReportEndFunction(
    tenantIdentifier: "Payroll.Report",
    userIdentifier: "peter.schmid@foo.com",
    regulationName: "Payroll.Report")]
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
        reportName: "EmployeeCaseValues",
        language: Language.German,
        parameters: "{ \"PayrollId\": \"Payroll.Report\" }")]
    public object ReportEndScript()
    {
        // payroll
        var payrollId = ResolveParameterPayrollId();
        if (!payrollId.HasValue)
        {
            return -1;
        }

        // employees
        var employees = Tables["Employees"];
        if (employees == null)
        {
            // no start query, query all employees
            employees = ExecuteQuery("QueryEmployees",
                new QueryParameters()
                    .Parameter(nameof(TenantId), TenantId));
            AddTable(employees);
        }
        if (employees == null || employees.Rows.Count == 0)
        {
            // no employees available
            return -2;
        }
        var employeeIds = employees.GetValues<int>("Id");

        // employee case values
        var caseValuesTable = ExecuteEmployeeTimeCaseValueQuery("CaseValues", payrollId.Value, employeeIds,
            new CaseValueColumn[]
            {
                // simple columns
                new("Monatslohn"),
                new("EmploymentLevel"),
                new("Geburtsdatum"),
                // lookup column
                new("Location", "Location")
            },
            Language);
        AddTable(caseValuesTable);

        // employee to case value relation
        AddRelation("EmployeeCaseValues", employees.TableName, caseValuesTable.TableName, "EmployeeId");

        return 0;
    }
}