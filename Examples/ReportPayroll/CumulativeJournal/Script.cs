using System.Collections.Generic;
using System.Data;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;
using PayrollEngine.Client.Scripting.Report;
using Date = PayrollEngine.Client.Scripting.Date;
// ReSharper disable ClassNeverInstantiated.Global

// ReSharper disable once CheckNamespace
namespace ReportPayroll.CumulativeJournal;

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
        reportName: "CumulativeJournal",
        culture: "de-CH",
        parameters: "{ \"JournalYear\": \"2025\"}")]
    public object Execute()
    {
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
            // no employees selected in query
            return null;
        }

        // journal year
        var year = GetParameter("JournalYear", Date.Now.Year);

        // overall result tables
        DataTable wageTypeResults = AddTable("WageTypeResults");
        DataTable collectorResults = AddTable("CollectorResults");

        // results for each employee
        foreach (var employee in employees.AsEnumerable())
        {
            // employee id
            if (employee["Id"] is not int employeeId)
            {
                throw new ScriptException("Missing employee id.");
            }

            // employee name for report display
            var firstName = employee["FirstName"] as string;
            var lastName = employee["LastName"] as string;

            // temporary tables for employee
            DataTable employeeWageTypeResults = AddTable("EmployeeWageTypeResults");
            // ReSharper disable once RedundantAssignment
            DataTable employeeWageTypes = AddTable("EmployeeWageTypes");
            DataTable employeeCollectorResults = AddTable("EmployeeCollectorResults");
            // ReSharper disable once RedundantAssignment
            DataTable employeeCollectors = AddTable("EmployeeCollectors");

            // results for each month in year
            for (var month = 1; month <= 12; month++)
            {
                // month period
                var periodStart = Date.MonthStart(year, month);

                // result request parameters (currently the same for wage types and collectors)
                var queryParameters = new Dictionary<string, string>
                {
                    { "TenantId", TenantId.ToString() },
                    { "EmployeeId", employeeId.ToString() },
                    { "PeriodStarts", $"[\"{periodStart.ToUtcString()}\"]" }
                };

                // query wage type results (cleanup previous query data)
                employeeWageTypes = ExecuteQuery("EmployeeWageTypes",
                    "GetConsolidatedWageTypeResults", queryParameters);
                if (employeeWageTypes != null && employeeWageTypes.Rows.Count > 0)
                {
                    // rename value column to month column
                    employeeWageTypes.RenameColumn("Value", $"M{month}");
                    // set merge column
                    employeeWageTypes.SetPrimaryKey("WageTypeNumber");
                    // merge results by wage type number
                    employeeWageTypeResults.Merge(employeeWageTypes, false, MissingSchemaAction.AddWithKey);
                }
                else
                {
                    employeeWageTypeResults.Columns.Add($"M{month}", typeof(decimal));
                }

                // query collector results (cleanup previous query data)
                employeeCollectors = ExecuteQuery("EmployeeCollectors",
                    "GetConsolidatedCollectorResults", queryParameters);
                if (employeeCollectors != null && employeeCollectors.Rows.Count > 0)
                {
                    // rename value column to month column
                    employeeCollectors.RenameColumn("Value", $"M{month}");
                    // set merge column
                    employeeCollectors.SetPrimaryKey("CollectorName");
                    // merge results by collector name
                    employeeCollectorResults.Merge(employeeCollectors, false, MissingSchemaAction.AddWithKey);
                }
                else
                {
                    employeeCollectorResults.Columns.Add($"M{month}", typeof(decimal));
                }
            }

            // add employee name columns and populate them for template display
            if (employeeWageTypeResults.Rows.Count > 0)
            {
                employeeWageTypeResults.Columns.Add("FirstName", typeof(string));
                employeeWageTypeResults.Columns.Add("LastName", typeof(string));
                foreach (DataRow row in employeeWageTypeResults.Rows)
                {
                    row["FirstName"] = firstName;
                    row["LastName"] = lastName;
                }
            }
            if (employeeCollectorResults.Rows.Count > 0)
            {
                employeeCollectorResults.Columns.Add("FirstName", typeof(string));
                employeeCollectorResults.Columns.Add("LastName", typeof(string));
                foreach (DataRow row in employeeCollectorResults.Rows)
                {
                    row["FirstName"] = firstName;
                    row["LastName"] = lastName;
                }
            }

            // mark summary rows before merge
            if (!employeeWageTypeResults.Columns.Contains("IsSummary"))
                employeeWageTypeResults.Columns.Add("IsSummary", typeof(int));
            foreach (DataRow row in employeeWageTypeResults.Rows)
            {
                var wtn = Convert.ToDecimal(row["WageTypeNumber"]);
                row["IsSummary"] = (wtn == 200m || wtn == 300m) ? 1 : 0;
            }

            // merge employee results to overall wage type results (remove primary key to append records)
            employeeWageTypeResults.RemovePrimaryKey();
            wageTypeResults.Merge(employeeWageTypeResults);

            // merge employee results to overall collector results (remove primary key to append records)
            employeeCollectorResults.RemovePrimaryKey();
            collectorResults.Merge(employeeCollectorResults);

            // cleanup temporary employee working tables
            RemoveTables("EmployeeWageTypeResults", "EmployeeCollectorResults", "EmployeeWageTypes", "EmployeeCollectors");
        }

        // wage type results sum
        var hasWageTypeResults = wageTypeResults != null && wageTypeResults.Rows.Count > 0;
        if (hasWageTypeResults)
        {
            wageTypeResults.AddColumn<decimal>("Total", "IIF(M1 IS NULL, 0, M1) + IIF(M2 IS NULL, 0, M2) + IIF(M3 IS NULL, 0, M3) + IIF(M4 IS NULL, 0, M4) + IIF(M5 IS NULL, 0, M5) + IIF(M6 IS NULL, 0, M6) + IIF(M7 IS NULL, 0, M7) + IIF(M8 IS NULL, 0, M8) + IIF(M9 IS NULL, 0, M9) + IIF(M10 IS NULL, 0, M10) + IIF(M11 IS NULL, 0, M11) + IIF(M12 IS NULL, 0, M12)");
            // remove empty rows
            wageTypeResults.DeleteRows("Total = 0");
            // sort by employee and wage type number (in-place to preserve table reference)
            var sortedView = new DataView(wageTypeResults) { Sort = "EmployeeId ASC, WageTypeNumber ASC" };
            var sortedRows = sortedView.ToTable();
            wageTypeResults.Clear();
            foreach (DataRow row in sortedRows.Rows)
                wageTypeResults.ImportRow(row);
            // per-employee, per-month presence flags: HasM1..HasM12 = 1 when the
            // employee has at least one non-zero value in that month column.
            // Used by the template to keep zeros visible in months that already
            // show numbers for that employee (instead of hiding all zeros).
            for (var m = 1; m <= 12; m++)
                wageTypeResults.Columns.Add($"HasM{m}", typeof(int));
            foreach (var empGroup in wageTypeResults.AsEnumerable().GroupBy(r => r["EmployeeId"]))
            {
                for (var m = 1; m <= 12; m++)
                {
                    var col = $"M{m}";
                    var hasValue = empGroup.Any(r => r[col] != DBNull.Value && Convert.ToDecimal(r[col]) != 0m);
                    foreach (var row in empGroup)
                        row[$"HasM{m}"] = hasValue ? 1 : 0;
                }
            }
            // report relations: results are related toward employee
            AddRelation("EmployeeWageTypeResults", employees.TableName, wageTypeResults.TableName, "EmployeeId");
        }

        // collector results sum
        bool hasCollectorResults = collectorResults != null && collectorResults.Rows.Count > 0;
        if (hasCollectorResults)
        {
            collectorResults.AddColumn<decimal>("Total", "IIF(M1 IS NULL, 0, M1) + IIF(M2 IS NULL, 0, M2) + IIF(M3 IS NULL, 0, M3) + IIF(M4 IS NULL, 0, M4) + IIF(M5 IS NULL, 0, M5) + IIF(M6 IS NULL, 0, M6) + IIF(M7 IS NULL, 0, M7) + IIF(M8 IS NULL, 0, M8) + IIF(M9 IS NULL, 0, M9) + IIF(M10 IS NULL, 0, M10) + IIF(M11 IS NULL, 0, M11) + IIF(M12 IS NULL, 0, M12)");
            // remove empty rows
            collectorResults.DeleteRows("Total = 0");
            // per-employee, per-month presence flags (same logic as wageTypeResults)
            for (var m = 1; m <= 12; m++)
                collectorResults.Columns.Add($"HasM{m}", typeof(int));
            foreach (var empGroup in collectorResults.AsEnumerable().GroupBy(r => r["EmployeeId"]))
            {
                for (var m = 1; m <= 12; m++)
                {
                    var col = $"M{m}";
                    var hasValue = empGroup.Any(r => r[col] != DBNull.Value && Convert.ToDecimal(r[col]) != 0m);
                    foreach (var row in empGroup)
                        row[$"HasM{m}"] = hasValue ? 1 : 0;
                }
            }
            // report relations: results are related toward employee
            AddRelation("EmployeeCollectorResults", employees.TableName, collectorResults.TableName, "EmployeeId");
        }

        // empty report
        if (!hasWageTypeResults && !hasCollectorResults)
        {
            employees.Clear();
        }

        AddReportLog($"Cumulative Journal Report: {wageTypeResults?.Rows.Count} wage types, {collectorResults?.Rows.Count} collectors");

        return null;
    }
}
