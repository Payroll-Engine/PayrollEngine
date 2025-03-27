using System;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace

/// <summary>Extensions for <see cref="PayrollFunction"/></summary>
public static class WorkdayLookupExtensions
{
    /// <summary>
    /// Test available workday using the lookup Workdays
    /// </summary>
    /// <param name="function">Case change function</param>
    /// <param name="workDate">Work date</param>
    public static bool? IsLookupWorkday(this PayrollFunction function, DateTime workDate)
    {
        var lookup = function.GetLookup<string>(
            lookupName: "Workdays",
            lookupKey: workDate.ToString("yyyy-MM-dd"));
        if (lookup != null && bool.TryParse(lookup, out var available))
        {
            return available;
        }
        return null;
    }
}