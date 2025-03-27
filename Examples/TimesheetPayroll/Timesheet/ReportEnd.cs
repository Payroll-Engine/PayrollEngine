using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Report;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable CommentTypo
// ReSharper disable once CheckNamespace

/// <summary>Timesheet wage report end</summary>
public static partial class TimesheetWageReport
{
    /// <summary>End the wage report</summary>
    public static bool? End(ReportEndFunction function)
    {
        const string EmployeeId = "EmployeeId";
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrunJobParameter = "PayrunJobName";

        var employeeIdentifier = function.GetParameter<string>(EmployeeParameter);
        var payrunJobName = function.GetParameter<string>(PayrunJobParameter);
        if (string.IsNullOrWhiteSpace(employeeIdentifier) ||
            string.IsNullOrWhiteSpace(payrunJobName))
        {
            throw new ScriptException("Invalid report parameters.");
        }

        // employees query: /api/tenants/{tenantId}/employees
        var employees = function.ExecuteQuery("QueryEmployees", new QueryParameters()
                    .Parameter("TenantId", function.TenantId)
                    .EqualIdentifier(employeeIdentifier));
        var employee = employees.SingleRow();
        var employeeId = employee.Id();

        // payrun jobs query: /api/tenants/{tenantId}/payruns/jobs/employees/{employeeId}
        var payrunJobs = function.ExecuteQuery("QueryEmployeePayrunJobs", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .Parameter(EmployeeId, employeeId)
            .Filter(
                new EqualName(payrunJobName))
            .Select("Name", "PeriodStart", "PeriodEnd"));
        var payrunJob = payrunJobs.SingleRow();

        // payroll results query: /api/tenants/{tenantId}/payrollresults
        var payrollResults = function.ExecuteQuery("QueryPayrollResults", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .Filter(new Equals("PayrunJobId", payrunJob.Id()).And(
                        new Equals(EmployeeId, employeeId))));
        var payrollResultId = payrollResults.SingleRowId();

        // wage types query: /api/tenants/{tenantId}/payrollresults/{payrollResultId}/wagetypes
        var wageTypes = function.ExecuteQuery("WageTypes", "QueryWageTypeResults", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .Parameter("PayrollResultId", payrollResultId));

        // collectors query: /api/tenants/{tenantId}/payrollresults/{payrollResultId}/collectors
        var collectors = function.ExecuteQuery("Collectors", "QueryCollectorResults", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .Parameter("PayrollResultId", payrollResultId));

        // empty report
        if (!wageTypes.Any() && !collectors.Any())
        {
            return true;
        }

        // additional employee data
        employees.AddColumn<DateTime>("PeriodStart");
        employees.AddColumn<DateTime>("PeriodEnd");
        employee["PeriodStart"] = payrunJob.GetValue<DateTime>("PeriodStart");
        employee["PeriodEnd"] = payrunJob.GetValue<DateTime>("PeriodEnd");

        // result tables and relations
        function.AddTable(employees);
        if (wageTypes.Any())
        {
            wageTypes.AddLocalizationColumn(function.UserCulture, "WageTypeName");
            wageTypes.AddRelationColumn(EmployeeId, employeeId);
            function.AddTable(wageTypes);
            function.AddRelation("EmployeeWageTypes", employees.TableName, wageTypes.TableName, EmployeeId);
        }
        if (collectors.Any())
        {
            collectors.AddLocalizationColumn(function.UserCulture, "CollectorName");
            collectors.AddRelationColumn(EmployeeId, employeeId);
            function.AddTable(collectors);
            function.AddRelation("EmployeeCollectors", employees.TableName, collectors.TableName, EmployeeId);
        }

        return true;
    }

}

/// <summary>Timesheet work time report end</summary>
public static partial class TimesheetWorkTimeReport
{

    /// <summary>End the work time report</summary>
    public static bool? End(ReportEndFunction function) =>
        End<WorkTime>(function);

    /// <summary>End the work time report</summary>
    public static bool? End<TWorkTime>(ReportEndFunction function)
        where TWorkTime : WorkTime, new()
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrollParameter = "PayrollName";
        const string WorkDayParameter = "WorkDay";

        var employeeIdentifier = function.GetParameter<string>(EmployeeParameter);
        var payrollName = function.GetParameter<string>(PayrollParameter);
        var workDay = function.GetParameter<DateTime>(WorkDayParameter);
        if (string.IsNullOrWhiteSpace(employeeIdentifier) ||
            string.IsNullOrWhiteSpace(payrollName) ||
            workDay == DateTime.MaxValue)
        {
            throw new ScriptException("Invalid report parameters.");
        }

        // employees query: /api/tenants/{tenantId}/employees
        var employees = function.ExecuteQuery("QueryEmployees", new QueryParameters()
                    .Parameter("TenantId", function.TenantId)
                    .EqualIdentifier(employeeIdentifier));
        var employee = employees.SingleRow();
        var employeeId = employee.Id();

        // payroll query: /api/tenants/{tenantId}/payrolls
        var payrolls = function.ExecuteQuery("QueryPayrolls", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .EqualName(payrollName));
        var payroll = payrolls.SingleRow();

        // working period
        var divisionId = payroll.GetValue<int>("DivisionId");
        if (employeeId == 0 || divisionId == 0)
        {
            throw new ScriptException("Missing period values.");
        }
        var period = function.GetCalendarPeriod(workDay, divisionId, employeeId);
        if (period.IsEmpty)
        {
            throw new ScriptException("Empty report period.");
        }

        // work times
        var workTimes = function.ExecuteRawCaseValueQuery(
            tableName: "WorkTimes",
            payrollId: payroll.Id(),
            employeeId,
            period: period,
            caseFieldNames: CaseObject.GetCaseFieldNames<TWorkTime>());

        // empty report
        if (!workTimes.Any())
        {
            return true;
        }

        // additional employee data
        employees.AddColumn<DateTime>("PeriodStart");
        employees.AddColumn<DateTime>("PeriodEnd");
        employee["PeriodStart"] = period.Start;
        employee["PeriodEnd"] = period.End;

        // result tables and relations
        function.AddTable(employees);
        workTimes.AddRelationColumn("EmployeeId", employeeId);
        function.AddTable(workTimes);
        function.AddRelation("EmployeeWorkTimes", employees.TableName, workTimes.TableName, "EmployeeId");

        return true;
    }
}