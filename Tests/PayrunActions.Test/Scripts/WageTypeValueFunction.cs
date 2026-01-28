namespace PayrollEngine.Client.Scripting.Function;

public partial class WageTypeValueFunction
{
    [ActionParameter("value", "The value to duplicate")]
    [CaseValidateAction("Duplicate", "Duplicate a value")]
    public ActionValue Duplicate(ActionValue value) =>
        value * 2;
}
