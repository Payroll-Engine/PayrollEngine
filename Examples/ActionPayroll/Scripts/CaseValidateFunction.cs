
namespace PayrollEngine.Client.Scripting.Function;

public partial class CaseValidateFunction
{
    [ActionIssue("MissingRegistrationNumber", "Missing registration number", 1)]
    [ActionIssue("InvalidRegistrationNumber", "(0) with invalid registration number: (1)", 2)]
    [ActionParameter("caseFieldName", "The case field name")]
    [ActionParameter("registrationNumber", "The registration number text")]
    [CaseValidateAction("CheckRegistrationNumber", "Validate a structured registration number with ISO 7064 check digit")]
    public bool CheckRegistrationNumber(string caseFieldName, string registrationNumber)
    {
        if (string.IsNullOrWhiteSpace(registrationNumber))
        {
            AddCaseAttributeIssue("MissingRegistrationNumber");
            return false;
        }

        // extract check value: strip prefix and separators
        var checkValue = registrationNumber.RemoveFromStart("REG-").Replace(".", string.Empty);

        try
        {
            // ISO 7064 digit check with modulus, radix, character-set and double-check-digit option
            new CheckDigit(11, 1, "0123456789", false).Check(checkValue);

            // predefined digit checks: Mod11Radix2, Mod37Radix2, Mod97Radix10, Mod661Radix26, Mod1271Radix36
            // CheckDigit.Mod11Radix2.Check(checkValue);

            LogInformation($"Valid registration number {registrationNumber}.");
            return true;
        }
        catch (CheckDigitException)
        {
            LogError($"Invalid registration number check value {checkValue}.");
            AddCaseAttributeIssue("InvalidRegistrationNumber", caseFieldName, $"Invalid registration number: {registrationNumber}");
        }
        return false;
    }
}
