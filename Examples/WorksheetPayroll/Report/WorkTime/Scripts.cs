using System;
using System.Linq;
using System.Data;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Report;
using PayrollEngine.Client.Scripting.Runtime;

// ReSharper disable StringLiteralTypo

namespace WorksheetPayroll.Report.WorkTime;

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
        reportName: "WorkTime",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\" }")]
    public object ReportBuildScript()
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrollParameter = "PayrollName";
        const string WorkDayParameter = "WorkDay";

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
        // employee selection
        if (employee == null)
        {
            BuildInputList(
                table: employees,
                reportParameter: EmployeeParameter,
                identifierFunc: row => row.Identifier(),
                displayFunc: row => $"{row["FirstName"]} {row["LastName"]}");
            BuildInvalid();
            HideParameter(PayrollParameter, WorkDayParameter);
            return null;
        }
        SetParameterReadOnly(EmployeeParameter, true);

        // payrolls
        var payrolls = ExecuteQuery("QueryPayrolls", new QueryParameters()
            .Parameter("TenantId", TenantId));
        if (!payrolls.Any())
        {
            throw new ScriptException("Missing payrolls.");
        }

        // selected payroll
        DataRow payroll = null;
        ShowParameter(PayrollParameter);
        var payrollName = GetParameter<string>(PayrollParameter);
        if (!string.IsNullOrWhiteSpace(payrollName))
        {
            payroll = payrolls.FindFirstRow("Name", payrollName);
        }
        // payroll selection
        if (payroll == null)
        {
            // available divisions
            var divisions = ExecuteQuery("QueryDivisions", new QueryParameters()
                    .Parameter("TenantId", TenantId));
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
                SetParameter(PayrollParameter, payroll.Name());
                SetParameterReadOnly(PayrollParameter, true);
            }
            else
            {
                BuildInputList(
                        table: payrolls,
                        reportParameter: PayrollParameter,
                        identifierFunc: row => row.Id(),
                        displayFunc: row => row.Name());
                BuildInvalid();
                HideParameter(WorkDayParameter);
                return null;
            }
        }

        // work day
        ShowParameter(WorkDayParameter);
        var workDay = GetParameter<DateTime>(WorkDayParameter);
        if (workDay == DateTime.MinValue)
        {
            // fallback working day
            workDay = DateTime.Today;
            SetParameter(WorkDayParameter, workDay);
        }

        // working period
        var employeeId = employee.Id();
        var divisionId = payroll.GetValue<int>("DivisionId");
        if (employeeId == 0 || divisionId == 0)
        {
            throw new ScriptException("Missing period values.");
        }
        var period = GetDerivedCalendarPeriod(workDay, divisionId, employeeId);
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
        reportName: "WorkTime",
        culture: "en-US",
        parameters: "{ \"EmployeeIdentifier\": \"višnja.müller@foo.com Test 1\", " +
                    "\"PayrollName\": \"WorksheetPayroll\", " +
                    "\"WorkDay\": \"2025-02-17T00:00:00.0Z\" }")]
    public object ReportEndScript()
    {
        const string EmployeeParameter = "EmployeeIdentifier";
        const string PayrollParameter = "PayrollName";
        const string WorkDayParameter = "WorkDay";

        var employeeIdentifier = GetParameter<string>(EmployeeParameter);
        var payrollName = GetParameter<string>(PayrollParameter);
        var workDay = GetParameter<DateTime>(WorkDayParameter);
        if (string.IsNullOrWhiteSpace(employeeIdentifier) ||
            string.IsNullOrWhiteSpace(payrollName) ||
            workDay == DateTime.MaxValue)
        {
            throw new ScriptException("Invalid report parameters.");
        }

        // employees
        var employees = ExecuteQuery("QueryEmployees", new QueryParameters()
                    .Parameter("TenantId", TenantId)
                    .EqualIdentifier(employeeIdentifier));
        var employee = employees.SingleRow();
        var employeeId = employee.Id();

        // payrolls
        var payrolls = ExecuteQuery("QueryPayrolls", new QueryParameters()
            .Parameter("TenantId", TenantId)
            .EqualName(payrollName));
        var payroll = payrolls.SingleRow();

        // working period
        var divisionId = payroll.GetValue<int>("DivisionId");
        if (employeeId == 0 || divisionId == 0)
        {
            throw new ScriptException("Missing period values.");
        }
        var period = GetDerivedCalendarPeriod(workDay, divisionId, employeeId);
        if (period.IsEmpty)
        {
            throw new ScriptException("Empty report period.");
        }

        // work times
        var workTimes = ExecuteRawCaseValueQuery(
            tableName: "WorkTimes",
            payrollId: payroll.Id(),
            employeeId,
            period: period,
            caseFieldNames: [
                new("WorkdayDate"),
                new("WorkdayStart"),
                new("WorkdayEnd"),
                new("WorkdayBreak"),
                new("WorkdayHours")
            ]);

        // empty report
        if (!workTimes.Any())
        {
            return 0;
        }

        // additional employee data
        employees.AddColumn<DateTime>("PeriodStart");
        employees.AddColumn<DateTime>("PeriodEnd");
        employee["PeriodStart"] = period.Start;
        employee["PeriodEnd"] = period.End;

        // result tables and relations
        AddTable(employees);
        workTimes.AddRelationColumn("EmployeeId", employeeId);
        AddTable(workTimes);
        AddRelation("EmployeeWorkTimes", employees.TableName, workTimes.TableName, "EmployeeId");

        return 0;
    }
}