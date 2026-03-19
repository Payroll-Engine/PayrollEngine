using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;
using PayrollEngine.Client.Scripting.Report;
using Date = PayrollEngine.Client.Scripting.Date;
// ReSharper disable ClassNeverInstantiated.Global

// ReSharper disable once CheckNamespace
namespace ReportPayroll.Payslip;

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
        reportName: "Payslip",
        culture: "de-CH",
        parameters: "{ \"PayslipYear\": \"2025\", \"PayslipMonth\": \"03\", \"EmployeeIdentifier\": \"miller.alice@example.com\" }")]
    public object Execute()
    {
        // employees
        var employees = Tables["Employees"];
        if (employees == null)
        {
            employees = ExecuteQuery("QueryEmployees",
                new QueryParameters()
                    .Parameter(nameof(TenantId), TenantId));
            AddTable(employees);
        }
        if (employees == null || employees.Rows.Count == 0)
        {
            return null;
        }

        // filter to single employee if EmployeeIdentifier parameter is set
        var employeeIdentifier = GetParameter("EmployeeIdentifier");
        if (!string.IsNullOrWhiteSpace(employeeIdentifier))
        {
            var toDelete = employees.AsEnumerable()
                .Where(r => !string.Equals(
                    r["Identifier"] as string,
                    employeeIdentifier,
                    StringComparison.OrdinalIgnoreCase))
                .ToList();
            foreach (var row in toDelete)
                row.Delete();
            employees.AcceptChanges();
        }
        if (employees.Rows.Count == 0)
        {
            return null;
        }

        // payslip period
        var year = GetParameter("PayslipYear", Date.Now.Year);
        var month = GetParameter("PayslipMonth", Date.Now.Month);

        // overall result tables
        DataTable wageTypeResults = AddTable("WageTypeResults");
        DataTable collectorResults = AddTable("CollectorResults");

        // results for each employee
        foreach (var employee in employees.AsEnumerable())
        {
            if (employee["Id"] is not int employeeId)
            {
                throw new ScriptException("Missing employee id.");
            }

            var firstName = employee["FirstName"] as string;
            var lastName = employee["LastName"] as string;

            // ── Wage types ────────────────────────────────────────────────────

            DataTable employeeWageTypeResults = AddTable("EmployeeWageTypeResults");
            // pre-create temp tables so RemoveTables never fails
            AddTable("EmployeeWageTypes");
            AddTable("EmployeeWageTypesOriginal");
            // RetroValue accumulator: keyed by WageTypeNumber
            var wageTypeRetroAccum = new Dictionary<decimal, decimal>();

            for (var m = 1; m <= month; m++)
            {
                var periodStart = Date.MonthStart(year, m).ToUtcString();

                var queryParams = new Dictionary<string, string>
                {
                    { "TenantId", TenantId.ToString() },
                    { "EmployeeId", employeeId.ToString() },
                    { "PeriodStarts", $"[\"{periodStart}\"]" }
                };

                // consolidated value for this month (includes retro corrections settled so far)
                var consolidated = ExecuteQuery("EmployeeWageTypes",
                    "GetConsolidatedWageTypeResults", queryParams);

                if (m < month)
                {
                    // prior months: rename Value → Mm for YTD summation
                    if (consolidated != null && consolidated.Rows.Count > 0)
                    {
                        consolidated.RenameColumn("Value", $"M{m}");
                        consolidated.SetPrimaryKey("WageTypeNumber");
                        employeeWageTypeResults.Merge(consolidated, false, MissingSchemaAction.AddWithKey);
                    }
                    else
                    {
                        employeeWageTypeResults.Columns.Add($"M{m}", typeof(decimal));
                    }

                    // original value at end of this month (evaluationDate = start of m+1)
                    // → value as calculated by the original payrun, before any later retro corrections
                    var nextStart = m < 12
                        ? Date.MonthStart(year, m + 1).ToUtcString()
                        : Date.MonthStart(year + 1, 1).ToUtcString();
                    var originalParams = new Dictionary<string, string>
                    {
                        { "TenantId", TenantId.ToString() },
                        { "EmployeeId", employeeId.ToString() },
                        { "PeriodStarts", $"[\"{periodStart}\"]" },
                        { "EvaluationDate", nextStart }
                    };
                    var original = ExecuteQuery("EmployeeWageTypesOriginal",
                        "GetConsolidatedWageTypeResults", originalParams);

                    // accumulate retro delta per WageTypeNumber
                    // build original lookup: Value column (not yet renamed)
                    var originalLookup = new Dictionary<decimal, decimal>();
                    if (original != null)
                    {
                        foreach (DataRow row in original.Rows)
                        {
                            if (row["WageTypeNumber"] is decimal wtn)
                                originalLookup[wtn] = row["Value"] is decimal ov ? ov : 0m;
                        }
                    }

                    // accumulate delta per WageTypeNumber from consolidated (already renamed to Mm)
                    if (consolidated != null && consolidated.Rows.Count > 0)
                    {
                        foreach (DataRow row in consolidated.Rows)
                        {
                            if (row["WageTypeNumber"] is not decimal wtn) continue;
                            var consVal = row[$"M{m}"] is decimal cv ? cv : 0m;
                            originalLookup.TryGetValue(wtn, out var origVal);
                            var delta = consVal - origVal;
                            if (delta != 0m)
                            {
                                wageTypeRetroAccum.TryGetValue(wtn, out var existing);
                                wageTypeRetroAccum[wtn] = existing + delta;
                            }
                        }
                    }
                }
                else
                {
                    // payslip month: keep as CurrentValue
                    if (consolidated != null && consolidated.Rows.Count > 0)
                    {
                        consolidated.RenameColumn("Value", "CurrentValue");
                        consolidated.SetPrimaryKey("WageTypeNumber");
                        employeeWageTypeResults.Merge(consolidated, false, MissingSchemaAction.AddWithKey);
                    }
                    else
                    {
                        employeeWageTypeResults.Columns.Add("CurrentValue", typeof(decimal));
                    }
                }
            }

            if (employeeWageTypeResults.Rows.Count > 0)
            {
                // YTD = M1 + M2 + ... + M(month-1) + CurrentValue
                var ytdParts = Enumerable.Range(1, month - 1)
                    .Select(m => $"IIF(M{m} IS NULL, 0, M{m})")
                    .Append("IIF(CurrentValue IS NULL, 0, CurrentValue)");
                employeeWageTypeResults.AddColumn<decimal>("YtdValue",
                    string.Join(" + ", ytdParts));

                employeeWageTypeResults.AddColumn<decimal>("Value",
                    "IIF(CurrentValue IS NULL, 0, CurrentValue)");

                // inject accumulated RetroValue from accumulator dictionary
                employeeWageTypeResults.Columns.Add("RetroValue", typeof(decimal));
                foreach (DataRow row in employeeWageTypeResults.Rows)
                {
                    if (row["WageTypeNumber"] is decimal wtn &&
                        wageTypeRetroAccum.TryGetValue(wtn, out var retro))
                    {
                        row["RetroValue"] = retro;
                    }
                    else
                    {
                        row["RetroValue"] = 0m;
                    }
                }

                employeeWageTypeResults.DeleteRows("YtdValue = 0");

                if (employeeWageTypeResults.Rows.Count > 0)
                {
                    employeeWageTypeResults.Columns.Add("FirstName", typeof(string));
                    employeeWageTypeResults.Columns.Add("LastName", typeof(string));
                    foreach (DataRow row in employeeWageTypeResults.Rows)
                    {
                        row["FirstName"] = firstName;
                        row["LastName"] = lastName;
                    }
                    employeeWageTypeResults.RemovePrimaryKey();
                    wageTypeResults.Merge(employeeWageTypeResults);
                }
            }

            // ── Collectors ────────────────────────────────────────────────────

            DataTable employeeCollectorResults = AddTable("EmployeeCollectorResults");
            AddTable("EmployeeCollectors");
            AddTable("EmployeeCollectorsOriginal");
            var collectorRetroAccum = new Dictionary<string, decimal>();

            for (var m = 1; m <= month; m++)
            {
                var periodStart = Date.MonthStart(year, m).ToUtcString();

                var queryParams = new Dictionary<string, string>
                {
                    { "TenantId", TenantId.ToString() },
                    { "EmployeeId", employeeId.ToString() },
                    { "PeriodStarts", $"[\"{periodStart}\"]" }
                };

                var consolidated = ExecuteQuery("EmployeeCollectors",
                    "GetConsolidatedCollectorResults", queryParams);

                if (m < month)
                {
                    if (consolidated != null && consolidated.Rows.Count > 0)
                    {
                        consolidated.RenameColumn("Value", $"M{m}");
                        consolidated.SetPrimaryKey("CollectorName");
                        employeeCollectorResults.Merge(consolidated, false, MissingSchemaAction.AddWithKey);
                    }
                    else
                    {
                        employeeCollectorResults.Columns.Add($"M{m}", typeof(decimal));
                    }

                    var nextStart = m < 12
                        ? Date.MonthStart(year, m + 1).ToUtcString()
                        : Date.MonthStart(year + 1, 1).ToUtcString();
                    var originalParams = new Dictionary<string, string>
                    {
                        { "TenantId", TenantId.ToString() },
                        { "EmployeeId", employeeId.ToString() },
                        { "PeriodStarts", $"[\"{periodStart}\"]" },
                        { "EvaluationDate", nextStart }
                    };
                    var original = ExecuteQuery("EmployeeCollectorsOriginal",
                        "GetConsolidatedCollectorResults", originalParams);

                    if (consolidated != null && original != null)
                    {
                        var originalLookup = new Dictionary<string, decimal>();
                        foreach (DataRow row in original.Rows)
                        {
                            if (row["CollectorName"] is string cn)
                                originalLookup[cn] = row["Value"] is decimal ov ? ov : 0m;
                        }
                        foreach (DataRow row in consolidated.Rows)
                        {
                            if (row["CollectorName"] is not string cn) continue;
                            var consVal = row[$"M{m}"] is decimal cv ? cv : 0m;
                            originalLookup.TryGetValue(cn, out var origVal);
                            var delta = consVal - origVal;
                            if (delta != 0m)
                            {
                                collectorRetroAccum.TryGetValue(cn, out var existing);
                                collectorRetroAccum[cn] = existing + delta;
                            }
                        }
                    }
                }
                else
                {
                    if (consolidated != null && consolidated.Rows.Count > 0)
                    {
                        consolidated.RenameColumn("Value", "CurrentValue");
                        consolidated.SetPrimaryKey("CollectorName");
                        employeeCollectorResults.Merge(consolidated, false, MissingSchemaAction.AddWithKey);
                    }
                    else
                    {
                        employeeCollectorResults.Columns.Add("CurrentValue", typeof(decimal));
                    }
                }
            }

            if (employeeCollectorResults.Rows.Count > 0)
            {
                var ytdParts = Enumerable.Range(1, month - 1)
                    .Select(m => $"IIF(M{m} IS NULL, 0, M{m})")
                    .Append("IIF(CurrentValue IS NULL, 0, CurrentValue)");
                employeeCollectorResults.AddColumn<decimal>("YtdValue",
                    string.Join(" + ", ytdParts));

                employeeCollectorResults.AddColumn<decimal>("Value",
                    "IIF(CurrentValue IS NULL, 0, CurrentValue)");

                employeeCollectorResults.Columns.Add("RetroValue", typeof(decimal));
                foreach (DataRow row in employeeCollectorResults.Rows)
                {
                    if (row["CollectorName"] is string cn &&
                        collectorRetroAccum.TryGetValue(cn, out var retro))
                    {
                        row["RetroValue"] = retro;
                    }
                    else
                    {
                        row["RetroValue"] = 0m;
                    }
                }

                employeeCollectorResults.DeleteRows("YtdValue = 0");

                if (employeeCollectorResults.Rows.Count > 0)
                {
                    employeeCollectorResults.Columns.Add("FirstName", typeof(string));
                    employeeCollectorResults.Columns.Add("LastName", typeof(string));
                    foreach (DataRow row in employeeCollectorResults.Rows)
                    {
                        row["FirstName"] = firstName;
                        row["LastName"] = lastName;
                    }
                    employeeCollectorResults.RemovePrimaryKey();
                    collectorResults.Merge(employeeCollectorResults);
                }
            }

            RemoveTables("EmployeeWageTypeResults", "EmployeeWageTypes", "EmployeeWageTypesOriginal",
                "EmployeeCollectorResults", "EmployeeCollectors", "EmployeeCollectorsOriginal");
        }

        // sort and relate wage type results
        var hasWageTypeResults = wageTypeResults != null && wageTypeResults.Rows.Count > 0;
        if (hasWageTypeResults)
        {
            var sortedView = new DataView(wageTypeResults) { Sort = "EmployeeId ASC, WageTypeNumber ASC" };
            var sortedRows = sortedView.ToTable();
            wageTypeResults.Clear();
            foreach (DataRow row in sortedRows.Rows)
                wageTypeResults.ImportRow(row);
            AddRelation("EmployeeWageTypeResults", employees.TableName, wageTypeResults.TableName, "EmployeeId");
        }

        var hasCollectorResults = collectorResults != null && collectorResults.Rows.Count > 0;
        if (hasCollectorResults)
        {
            AddRelation("EmployeeCollectorResults", employees.TableName, collectorResults.TableName, "EmployeeId");
        }

        if (!hasWageTypeResults && !hasCollectorResults)
        {
            employees.Clear();
        }

        AddReportLog($"Payslip Report: {year}-{month:D2}, employee: {employeeIdentifier}, " +
                     $"{wageTypeResults?.Rows.Count} wage type results, " +
                     $"{collectorResults?.Rows.Count} collector results");

        return null;
    }
}
