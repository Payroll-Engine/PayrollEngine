using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

public static class SickExtensions
{
    public static decimal GetSickDaysCount(this WageTypeValueFunction function) => 
        function.CaseValue["Krankheit"].TotalDaysByValue();
}    
