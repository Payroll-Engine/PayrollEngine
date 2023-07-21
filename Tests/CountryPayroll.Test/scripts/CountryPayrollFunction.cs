using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

namespace PayrollEngine.Country
{
    /// <summary>Country payroll function base class</summary>
    public class CountryPayrollFunction : CountryFunction
    {
        public new PayrollFunction Function { get; }

        public CountryPayrollFunction(object function) :
            base(function)
        {
            Function = (PayrollFunction)function;
        }

        public PayrollValue CurrentMonthWage
        {
            get
            {
                var values = Function.GetCaseValues("MonthlyWage", "EmploymentLevel");
                return values["MonthlyWage"] * values["EmploymentLevel"];
            }
        }
    }
}
