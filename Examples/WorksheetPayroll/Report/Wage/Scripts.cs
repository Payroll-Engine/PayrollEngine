using System;
using System.Data;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Report;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace WorksheetPayroll.Report.Wage;

[ReportBuildFunction(
    tenantIdentifier: "WorksheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "WorksheetRegulation")]
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
                    "\"PayrunJobName\": \"WorksheetPayrunJob.Week14.2025\" }")]
    public object ReportBuildScript()
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrunJobParameter = "PayrunJobName";

        // validation reset
        BuildValid();

        // employees
        var employees = ExecuteQuery("QueryEmployees", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .OrderBy("FirstName")
            .OrderBy("LastName"));
        if (!employees.Any())
        {
            throw new ScriptException("Missing employees.");
        }

        // employee selection
        DataRow employee = null;
        var employeeIdentifier = GetParameter<string>(EmployeeParameter);
        if (!string.IsNullOrWhiteSpace(employeeIdentifier))
        {
            employee = employees.FindFirstRow("Identifier", employeeIdentifier);
        }
        if (employee == null)
        {
            BuildInputList(
                table: employees,
                reportParameter: EmployeeParameter,
                identifierFunc: row => row.Identifier(),
                displayFunc: row => $"{row["FirstName"]} {row["LastName"]}");
            BuildInvalid();
            HideParameter(PayrunJobParameter);
            return null;
        }
        var employeeId = employee.Id();
        SetParameterReadOnly(EmployeeParameter, true);

        // payrun jobs
        var payrunJobs = ExecuteQuery("QueryEmployeePayrunJobs", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .Parameter("EmployeeId", employeeId)
            .Select("Name", "PeriodStart", "PeriodEnd"));
        if (!payrunJobs.Any())
        {
            BuildInvalid();
            AddInfo("Job", "Not available.");
            return null;
        }

        // payrun job
        DataRow payrunJob = null;
        ShowParameter(PayrunJobParameter);
        if (payrunJobs.IsSingleRow())
        {
            // single job
            payrunJob = payrunJobs.SingleRow();
            SetParameter(PayrunJobParameter, payrunJob.Name());
            SetParameterReadOnly(PayrunJobParameter, true);
        }
        else
        {
            var payrunJobName = GetParameter<string>(PayrunJobParameter);
            if (!string.IsNullOrWhiteSpace(payrunJobName))
            {
                payrunJob = payrunJobs.FindFirstRow("Name", payrunJobName);
            }
            // payrun job selection
            if (payrunJob == null)
            {
                BuildInputList(
                    table: payrunJobs,
                    reportParameter: PayrunJobParameter,
                    identifierFunc: row => row.Name());
                BuildInvalid();
                return null;
            }
        }

        // wage period
        var start = payrunJob.GetValue<DateTime>("PeriodStart");
        var end = payrunJob.GetValue<DateTime>("PeriodEnd");
        var period = new DatePeriod(start, end);
        AddInfo("Period", period.ToString());

        // ready to start
        return null;
    }
}

[ReportEndFunction(
    tenantIdentifier: "WorksheetTenant",
    userIdentifier: "lucy.smith@foo.com",
    regulationName: "WorksheetRegulation")]
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
                    "\"PayrunJobName\": \"WorksheetPayrunJob.Week14.2025\" }")]
    public object ReportEndScript()
    {
        const string EmployeeId = "EmployeeId";
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrunJobParameter = "PayrunJobName";

        var employeeIdentifier = GetParameter<string>(EmployeeParameter);
        var payrunJobName = GetParameter<string>(PayrunJobParameter);
        if (string.IsNullOrWhiteSpace(employeeIdentifier) ||
            string.IsNullOrWhiteSpace(payrunJobName))
        {
            throw new ScriptException("Invalid report parameters.");
        }

        // employees
        var employees = ExecuteQuery("QueryEmployees", new QueryParameters()
                    .Parameter("TenantId", TenantId)
                    .EqualIdentifier(employeeIdentifier));
        var employee = employees.SingleRow();
        var employeeId = employee.Id();

        // payrun jobs
        var payrunJobs = ExecuteQuery("QueryEmployeePayrunJobs", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .Parameter(EmployeeId, employeeId)
            .Filter(
                new EqualName(payrunJobName))
            .Select("Name", "PeriodStart", "PeriodEnd"));
        var payrunJob = payrunJobs.SingleRow();

        // payroll results
        var payrollResults = ExecuteQuery("QueryPayrollResults", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .Filter(new Equals("PayrunJobId", payrunJob.Id()).And(
                        new Equals(EmployeeId, employeeId))));
        var payrollResultId = payrollResults.SingleRowId();

        // wage types
        var wageTypes = ExecuteQuery("WageTypes", "QueryWageTypeResults", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .Parameter("PayrollResultId", payrollResultId));

        // collectors
        var collectors = ExecuteQuery("Collectors", "QueryCollectorResults", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .Parameter("PayrollResultId", payrollResultId));

        // empty report
        if (!wageTypes.Any() && !collectors.Any())
        {
            return 0;
        }

        // additional employee data
        employees.AddColumn<DateTime>("PeriodStart");
        employees.AddColumn<DateTime>("PeriodEnd");
        employee["PeriodStart"] = payrunJob.GetValue<DateTime>("PeriodStart");
        employee["PeriodEnd"] = payrunJob.GetValue<DateTime>("PeriodEnd");

        // result tables and relations
        AddTable(employees);
        if (wageTypes.Any())
        {
            wageTypes.AddLocalizationColumn(UserCulture, "WageTypeName");
            wageTypes.AddRelationColumn(EmployeeId, employeeId);
            AddTable(wageTypes);
            AddRelation("EmployeeWageTypes", employees.TableName, wageTypes.TableName, EmployeeId);
        }
        if (collectors.Any())
        {
            collectors.AddLocalizationColumn(UserCulture, "CollectorName");
            collectors.AddRelationColumn(EmployeeId, employeeId);
            AddTable(collectors);
            AddRelation("EmployeeCollectors", employees.TableName, collectors.TableName, EmployeeId);
        }

        return 0;
    }
}