using PayrollEngine;
using PayrollEngine.Client;
using System;
using System.Linq;
using PayrollEngine.Client.Test;
using PayrollEngine.Client.Test.Case;

namespace PayrollEngine.TestCase
{
    public class EmployeeTest : CaseCustomTest
    {
        public EmployeeTest(PayrollHttpClient httpClient, CaseTestContext context) :
            base(httpClient, context)
        {
        }

        public void EmployeeTest01Custom(CaseAvailableTest test)
        {
            //var caseValue = GetCasePeriodValue<decimal>("AHV AN Local");
            //if (caseValue > 0.05M)
            //{
              //  Assert.Fail("Montaslohn must be less than 0.05");
            //}
            var caseSet = GetCase("Monatslohn");
            Assert.AreEqual(test.Output, caseSet != null);
        }

        public void EmployeeTest02Custom(CaseBuildTest test)
        {
        }

        public void EmployeeTest03Custom(CaseValidateTest test)
        {
        }
    }
}
