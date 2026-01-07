using PayrollEngine.Client.Scripting;

#pragma warning disable IDE0130
namespace PayrollEngine.Client.Scripting.Function;
#pragma warning restore IDE0130

public partial class WageTypeValueFunction
{
    [ActionParameter("value", "The value to duplicate")]
    [CaseValidateAction("Duplicate", "Duplicate a value")]
    public ActionValue Duplicate(ActionValue value) =>
        value * 2;
}
