using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

public static class SickExtensions
{
    public static decimal GetDiseaseDaysCount(this WageTypeValueFunction function) => 
        function.CaseValue["Disease"].TotalDaysByValue();
}    
