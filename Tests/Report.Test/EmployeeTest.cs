using PayrollEngine;
using PayrollEngine.Client;
using System;
using System.Linq;
using PayrollEngine.Client.Test;
using PayrollEngine.Client.Test.Report;

namespace PayrollEngine.TestReport
{
    public class EmployeeTest : ReportCustomTest
    {
        public EmployeeTest(PayrollHttpClient httpClient, ReportTestContext context) :
            base(httpClient, context)
        {
        }

         public void EmployeeTest01Custom(ReportBuildTest test)
        {
            Assert.IsNotNull(test.Output);
        }

        public void EmployeeTest03Custom(ReportExecuteTest test)
        {
        }
    }
}
