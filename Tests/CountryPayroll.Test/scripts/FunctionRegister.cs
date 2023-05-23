//using System;
//using PayrollEngine.Client.Scripting;
//using PayrollEngine.Client.Scripting.Function;

namespace PayrollEngine.Client.Scripting.Function
{
    using PayrollEngine.Country;

    /// <summary>Base class for any scripting function</summary>
    public abstract partial class Function
    {
        private CountryFunction country;
        public CountryFunction Country => country ??= new(this);
    }

    /// <summary>Base class for any scripting function</summary>
    public abstract partial class PayrollFunction
    {
        private CountryPayrollFunction country;
        public CountryPayrollFunction Country => country ??= new(this);
    }

    // further country function registrations...
}
