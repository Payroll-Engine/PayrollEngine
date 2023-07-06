/* ExtendedWageTypeValueFunction */

using System;
using PayrollEngine.Client.Scripting.Function;
namespace ExtendedPayroll.Scripts;

/// <summary>Composite wage type value function</summary>
public class CompositeWageTypeValueFunction
{
    private WageTypeValueFunction Function { get; }

    public CompositeWageTypeValueFunction(WageTypeValueFunction function)
    {
        Function = function ?? throw new ArgumentNullException(nameof(function));
    }

    /// <summary>Get the salary</summary>
    public decimal GetSalary()
    {
        return Function.CaseValue["Salary"];
    }
}