using System;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

namespace PayrollEngine.Country
{
    /// <summary>Country function base class</summary>
    public class CountryFunction
    {
        public Function Function { get; }

        public CountryFunction(object function)
        {
            Function = (Function)function;
        }
    }
}
