/* ExtendedWageTypeValueRegister */

using ExtendedPayroll.Scripts;
namespace PayrollEngine.Client.Scripting.Function;

public partial class WageTypeValueFunction
{
    private CompositeWageTypeValueFunction function;
    public CompositeWageTypeValueFunction MyRegulation => function ??= new(this);
}
