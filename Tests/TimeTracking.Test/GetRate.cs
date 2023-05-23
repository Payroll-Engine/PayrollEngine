using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

public static class RateExtensions
{
    public static decimal GetRate(this WageTypeValueFunction function, DatePeriod period) =>
        (decimal)period.TotalHours * function.GetCaseValue(period.IsStartSunday() ? "Sunday Hourly Rate" : "Hourly Rate");
}    
