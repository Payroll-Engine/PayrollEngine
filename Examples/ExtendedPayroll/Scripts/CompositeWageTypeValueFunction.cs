/* ExtendedWageTypeValueFunction */

using System;
using PayrollEngine.Client.Scripting.Function;
namespace ExtendedPayroll.Scripts;

/// <summary>Composite wage type value function</summary>
public class CompositeWageTypeValueFunction(WageTypeValueFunction function)
{
    private WageTypeValueFunction Function { get; } = function ?? throw new ArgumentNullException(nameof(function));

    /// <summary>Get the salary</summary>
    public decimal GetSalary()
    {
        return Function.CaseValue["Salary"];
    }
}