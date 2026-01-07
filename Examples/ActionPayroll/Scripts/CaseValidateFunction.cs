
namespace PayrollEngine.Client.Scripting.Function;

public partial class CaseValidateFunction
{
    [ActionIssue("MissingUId", "Missing UId", 1)]
    [ActionIssue("InvalidUId", "(0) with invalid UID: (1)", 2)]
    [ActionParameter("caseFieldName", "The case field name")]
    [ActionParameter("uid", "The UID text")]
    [CaseValidateAction("CheckUId", "Validate for the Swiss company id (UID)")]
    public bool CheckUId(string caseFieldName, string uid)
    {
        if (string.IsNullOrWhiteSpace(uid))
        {
            AddCaseAttributeIssue("MissingUId");
            return false;
        }

        // extract check value
        var checkValue = uid.RemoveFromStart("CHE-").Replace(".", string.Empty);

        try
        {
            // ISO 7064 digit check with modulus, radix, character-set and double-check-digit option
            new CheckDigit(11, 1, "0123456789", false).Check(checkValue);

            // predefined digit checks: Mod11Radix2, Mod37Radix2, Mod97Radix10, Mod661Radix26, Mod1271Radix36
            // CheckDigit.Mod11Radix2.Check(checkValue);

            LogInformation($"Valid Uid {uid}.");
            return true;
        }
        catch (CheckDigitException)
        {
            LogError($"Invalid Uid check value {checkValue}.");
            AddCaseAttributeIssue("InvalidUId", caseFieldName, $"Invalid UId: {uid},");
        }
        return false;
    }
}
