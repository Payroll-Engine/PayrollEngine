using System.Linq;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Report;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo
// ReSharper disable once CheckNamespace

namespace ReportPayroll.EmployeeCaseValues;

[ReportBuildFunction(
    tenantIdentifier: "Report.Tenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "Report.Regulation")]
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
        culture: "de-CH",
        parameters: "{ \"AllEmployees\": \"true\" }")]
    public object ReportBuildScript()
    {
        // payroll selection
        if (!ExecuteInputListQuery(
                queryMethod: "QueryPayrolls",
                queryParameters: new QueryParameters()
                    .Parameter(nameof(TenantId), TenantId),
                reportParameter: "PayrollId",
                identifierFunc: row => row["Id"],
                displayFunc: row => $"{row["Name"]}").Any())
        {
            return null;
        }

        // employee(s) selection
        var allEmployees = GetParameter("AllEmployees", defaultValue: true);
        if (!allEmployees)
        {
            // employee list
            var employees = ExecuteInputListQuery(
                queryMethod: "QueryEmployees",
                queryParameters: new QueryParameters()
                    .Parameter(nameof(TenantId), TenantId),
                reportParameter: "EmployeeIdentifier",
                identifierFunc: row => row["Identifier"],
                displayFunc: row => $"{row["FirstName"]} {row["LastName"]}",
                selectFunc: identifiers => identifiers.First());
            if (employees.Count == 0)
            {
                return null;
            }
        }
        // parameter visibility
        SetParameterHidden("EmployeeIdentifier", allEmployees);

        return null;
    }
}

[ReportStartFunction(
    tenantIdentifier: "Report.Tenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "Report.Regulation")]
// ReSharper disable once UnusedType.Global
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
        culture: "de-CH")]
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
    tenantIdentifier: "Report.Tenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "Report.Regulation")]
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
        culture: "de-CH",
        parameters: "{ \"PayrollId\": \"Report.Payroll\" }")]
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
        var caseValuesTable = ExecuteEmployeeTimeCaseValueQuery(
            tableName: "CaseValues",
            payrollId: payrollId.Value,
            employeeIds: employeeIds,
            columns:
            [
                // simple columns
                new("MonthlyWage"),
                new("EmploymentLevel"),
                new("BirthDate"),
                // lookup column
                new("Location", "Location")
            ],
            culture: UserCulture);
        AddTable(caseValuesTable);

        // employee to case value relation
        AddRelation("EmployeeCaseValues", employees.TableName, caseValuesTable.TableName, "EmployeeId");

        return 0;
    }
}