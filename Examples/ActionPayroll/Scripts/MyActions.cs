using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

namespace ActionPayroll.Scripts;

[ActionProvider("MyActions", typeof(CaseChangeFunction))]
public class MyActions : CaseChangeActionsBase
{
    [ActionIssue("MissingUId", "Missing value (0)", 1)]
    [ActionIssue("InvalidUId", "(0) with invalid UID: (1)", 2)]
    [CaseValidateAction("CheckUId", "Validate for the Swiss UID")]
    public void CheckUId(CaseChangeActionContext context)
    {
        var sourceValue = GetActionValue<string>(context);
        if (sourceValue?.ResolvedValue == null)
        {
            AddIssue(context, "MissingUId", context.CaseFieldName);
            return;
        }

        try
        {
            // ISO 7064 digit check with modulus, radix, character-set and double-check-digit option
            new CheckDigit(11, 1, "0123456789", false).Check(sourceValue.ResolvedValue);

            // predefined digit checks: Mod11Radix2, Mod37Radix2, Mod97Radix10, Mod661Radix26, Mod1271Radix36
            // CheckDigit.Mod11Radix2.Check(sourceValue.ResolvedValue);
        }
        catch (CheckDigitException exception)
        {
            AddIssue(context, "InvalidUId", context.CaseFieldName, exception.CheckValue);
        }
    }
}
