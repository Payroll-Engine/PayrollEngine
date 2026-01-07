/* MyCaseChangeFunction */

namespace PayrollEngine.Client.Scripting.Function;

public partial class CaseChangeFunction
{
    [ActionParameter("caseFieldName", "The case field name",
        valueTypes: [StringType])]
    [ActionParameter("minimum", "The case field name",
        valueTypes: [IntType])]
    [CaseBuildAction("MinLimit", "Limit lower value")]
    public void MinLimit(string caseFieldName, int minimum)
    {
        var value = GetValue(caseFieldName) as int?;
        if (value != null && value < minimum)
        {
            SetValue(caseFieldName, minimum);
        }
    }

    [ActionParameter("caseFieldName", "The case field name",
        valueTypes: [StringType])]
    [ActionParameter("maximum", "The maximum value",
       valueTypes: [IntType, DecimalType, DateType])]
    [CaseBuildAction("MaxLimit", "My max limit function")]
    public void MaxLimit(string caseFieldName, int maximum)
    {
        var value = GetValue(caseFieldName) as int?;
        if (value != null && value > maximum)
        {
            SetValue(caseFieldName, maximum);
        }
    }
}
