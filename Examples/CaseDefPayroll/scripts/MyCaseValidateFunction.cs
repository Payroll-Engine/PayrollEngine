/* MyCaseValidateFunction */

namespace PayrollEngine.Client.Scripting.Function;

public partial class CaseValidateFunction
{
    [ActionParameter("caseFieldName", "The case field name",
        valueTypes: [StringType])]
    [CaseValidateAction("MyRule()", "My custom rule")]
    public void MaxLength(string caseFieldName)
    {
        var value = GetValue(caseFieldName) as string;
        if (!string.IsNullOrWhiteSpace(value) && value.Length > 3)
        {
            AddCaseIssue($"Maximum length is 3: {value}");
        }
    }
}
