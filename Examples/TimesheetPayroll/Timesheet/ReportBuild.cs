using System;
using System.Data;
using System.Linq;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Report;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable CommentTypo
// ReSharper disable once CheckNamespace

/// <summary>Timesheet wage report build</summary>
public static partial class TimesheetWageReport
{
    /// <summary>Build the wage report</summary>
    public static bool? Build(ReportBuildFunction function)
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrunJobParameter = "PayrunJobName";

        // validation reset
        function.BuildValid();

        // employees query: /api/tenants/{tenantId}/employees
        var employees = function.ExecuteQuery("QueryEmployees", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .OrderBy("FirstName")
            .OrderBy("LastName"));
        if (!employees.Any())
        {
            throw new ScriptException("Missing employees.");
        }

        // employee selection
        DataRow employee = null;
        var employeeIdentifier = function.GetParameter<string>(EmployeeParameter);
        if (!string.IsNullOrWhiteSpace(employeeIdentifier))
        {
            employee = employees.FindFirstRow("Identifier", employeeIdentifier);
        }
        if (employee == null)
        {
            function.BuildInputList(
                table: employees,
                reportParameter: EmployeeParameter,
                identifierFunc: row => row.Identifier(),
                displayFunc: row => $"{row["FirstName"]} {row["LastName"]}");
            function.BuildInvalid();
            function.HideParameter(PayrunJobParameter);
            return null;
        }
        var employeeId = employee.Id();
        function.SetParameterReadOnly(EmployeeParameter, true);

        // payrun jobs query: /api/tenants/{tenantId}/payruns/jobs/employees/{employeeId}
        var payrunJobs = function.ExecuteQuery("QueryEmployeePayrunJobs", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .Parameter("EmployeeId", employeeId)
            .Select("Name", "PeriodStart", "PeriodEnd"));
        if (!payrunJobs.Any())
        {
            function.BuildInvalid();
            function.AddInfo("Job", "Not available.");
            return null;
        }

        // payrun job
        DataRow payrunJob = null;
        function.ShowParameter(PayrunJobParameter);
        if (payrunJobs.IsSingleRow())
        {
            // single job
            payrunJob = payrunJobs.SingleRow();
            function.SetParameter(PayrunJobParameter, payrunJob.Name());
            function.SetParameterReadOnly(PayrunJobParameter, true);
        }
        else
        {
            var payrunJobName = function.GetParameter<string>(PayrunJobParameter);
            if (!string.IsNullOrWhiteSpace(payrunJobName))
            {
                payrunJob = payrunJobs.FindFirstRow("Name", payrunJobName);
            }
            // payrun job selection
            if (payrunJob == null)
            {
                function.BuildInputList(
                    table: payrunJobs,
                    reportParameter: PayrunJobParameter,
                    identifierFunc: row => row.Name());
                function.BuildInvalid();
                return null;
            }
        }

        // wage period
        var start = payrunJob.GetValue<DateTime>("PeriodStart");
        var end = payrunJob.GetValue<DateTime>("PeriodEnd");
        var period = new DatePeriod(start, end);
        function.AddInfo("Period", period.ToString());

        // ready to start
        return true;
    }
}

/// <summary>Timesheet work time report build</summary>
public static partial class TimesheetWorkTimeReport
{
    /// <summary>Build the work time report</summary>
    public static bool? Build(ReportBuildFunction function)
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrollParameter = "PayrollName";
        const string WorkDayParameter = "WorkDay";

        // validation reset
        function.BuildValid();

        // employees query: /api/tenants/{tenantId}/employees
        var employees = function.ExecuteQuery("QueryEmployees", new QueryParameters()
            .Parameter("TenantId", function.TenantId)
            .OrderBy("FirstName")
            .OrderBy("LastName"));
        if (!employees.Any())
        {
            throw new ScriptException("Missing employees.");
        }

        // employee selection
        DataRow employee = null;
        var employeeIdentifier = function.GetParameter<string>(EmployeeParameter);
        if (!string.IsNullOrWhiteSpace(employeeIdentifier))
        {
            employee = employees.FindFirstRow("Identifier", employeeIdentifier);
        }
        // employee selection
        if (employee == null)
        {
            function.BuildInputList(
                table: employees,
                reportParameter: EmployeeParameter,
                identifierFunc: row => row.Identifier(),
                displayFunc: row => $"{row["FirstName"]} {row["LastName"]}");
            function.BuildInvalid();
            function.HideParameter(PayrollParameter, WorkDayParameter);
            return null;
        }
        function.SetParameterReadOnly(EmployeeParameter, true);

        // payroll query: /api/tenants/{tenantId}/payrolls
        var payrolls = function.ExecuteQuery("QueryPayrolls", new QueryParameters()
            .Parameter("TenantId", function.TenantId));
        if (!payrolls.Any())
        {
            throw new ScriptException("Missing payrolls.");
        }

        // selected payroll
        DataRow payroll = null;
        function.ShowParameter(PayrollParameter);
        var payrollName = function.GetParameter<string>(PayrollParameter);
        if (!string.IsNullOrWhiteSpace(payrollName))
        {
            payroll = payrolls.FindFirstRow("Name", payrollName);
        }
        // payroll selection
        if (payroll == null)
        {
            // available divisions query: /api/tenants/{tenantId}/divisions
            var divisions = function.ExecuteQuery("QueryDivisions", new QueryParameters()
                    .Parameter("TenantId", function.TenantId));
            if (!divisions.Any())
            {
                throw new ScriptException("Missing divisions.");
            }
            var employeeDivisions = employee.GetListValue<string>("Divisions");
            var availableDivisions = divisions.SelectRows(
                x => employeeDivisions.Contains(x.Name()));
            if (!availableDivisions.Any())
            {
                throw new ScriptException("Missing employee divisions.");
            }

            // available payrolls filtered by employee divisions
            var availablePayrolls = payrolls.SelectRows(ap =>
                availableDivisions.Any(ad => Equals(ad.Id(), ap["DivisionId"])));
            if (availablePayrolls.Count == 0)
            {
                throw new ScriptException("Missing employee payroll.");
            }
            if (availablePayrolls.Count == 1)
            {
                payroll = availablePayrolls.First();
                function.SetParameter(PayrollParameter, payroll.Name());
                function.SetParameterReadOnly(PayrollParameter, true);
            }
            else
            {
                function.BuildInputList(
                        table: payrolls,
                        reportParameter: PayrollParameter,
                        identifierFunc: row => row.Id(),
                        displayFunc: row => row.Name());
                function.BuildInvalid();
                function.HideParameter(WorkDayParameter);
                return null;
            }
        }

        // work day
        function.ShowParameter(WorkDayParameter);
        var workDay = function.GetParameter<DateTime>(WorkDayParameter);
        if (workDay == DateTime.MinValue)
        {
            // fallback working day
            workDay = DateTime.Today;
            function.SetParameter(WorkDayParameter, workDay);
        }

        // working period
        var employeeId = employee.Id();
        var divisionId = payroll.GetValue<int>("DivisionId");
        if (employeeId == 0 || divisionId == 0)
        {
            throw new ScriptException("Missing period values.");
        }
        var period = function.GetCalendarPeriod(workDay, divisionId, employeeId);
        function.AddInfo("Period", period.ToString());

        // ready to start
        return true;
    }
}
