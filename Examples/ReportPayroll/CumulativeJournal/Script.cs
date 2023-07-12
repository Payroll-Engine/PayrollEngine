﻿using System.Collections.Generic;
using System.Data;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Runtime;
using PayrollEngine.Client.Scripting.Report;
using Date = PayrollEngine.Client.Scripting.Date;
// ReSharper disable ClassNeverInstantiated.Global

// ReSharper disable once CheckNamespace
namespace ReportPayroll.CumulativeJournal;

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
        reportName: "CumulativeJournal",
        culture: "de-CH",
        parameters: "{ \"Year\": \"2023\"}")]
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

        // report year
        var year = GetParameter("Year", Date.Now.Year);

        // overall result tables
        DataTable wageTypeResults = AddTable("WageTypeResults");
        DataTable collectorResults = AddTable("CollectorResults");

        // results for each employee
        foreach (var employee in employees.AsEnumerable())
        {
            // employee id
            if (employee["Id"] is not int employeeId)
            {
                throw new ScriptException("Missing employee id");
            }

            // temporary tables for employee
            DataTable employeeWageTypeResults = AddTable("EmployeeWageTypeResults");
            DataTable employeeWageTypes = AddTable("EmployeeWageTypes");
            DataTable employeeCollectorResults = AddTable("EmployeeCollectorResults");
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
        if (wageTypeResults != null && wageTypeResults.Rows.Count > 0)
        {
            wageTypeResults.AddColumn<decimal>("Total", "M1 + M2 + M3 + M4 + M5 + M6 + M7 + M8 + M9 + M10 + M11 + M12");
            // remove empty rows
            wageTypeResults.DeleteRows("Total = 0");
            // report relations: results are related toward employee
            AddRelation("EmployeeWageTypeResults", employees.TableName, wageTypeResults.TableName, "EmployeeId");
        }

        // collector results sum
        if (collectorResults != null && collectorResults.Rows.Count > 0)
        {
            collectorResults.AddColumn<decimal>("Total", "M1 + M2 + M3 + M4 + M5 + M6 + M7 + M8 + M9 + M10 + M11 + M12");
            // remove empty rows
            collectorResults.DeleteRows("Total = 0");
            // report relations: results are related toward employee
            AddRelation("EmployeeCollectorResults", employees.TableName, collectorResults.TableName, "EmployeeId");
        }
        
        AddReportLog($"Cumulative Journal Report: {wageTypeResults?.Rows.Count} wage types, {collectorResults?.Rows.Count} collectors");

        return null;
    }
}