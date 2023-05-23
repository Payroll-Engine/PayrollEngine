using System;
using PayrollEngine.Client.Scripting.Function;

public static class AgeExtension
{
    public static int GetCurrentAge(this Function function, DateTime? dateTime) => 
        dateTime.HasValue ? System.DateTime.UtcNow.Year - dateTime.Value.Year : 0;
}    
