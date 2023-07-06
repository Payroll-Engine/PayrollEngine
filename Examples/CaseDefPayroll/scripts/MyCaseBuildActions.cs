/* MyCaseBuildActions */
using System;
using ValueType = PayrollEngine.Client.Scripting.ValueType; 
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function; 

[ActionProvider("MyNamespace", typeof(CaseChangeFunction))] 
public class MyCaseBuildActions : CaseChangeActionsBase
{
     [CaseBuildAction("MinLimit", "My min limit function")]
     public void MinLimit(CaseChangeActionContext context, int minimum) 
     {
          //context.Function.LogWarning($"MyNamespace.MinLimit: {caseFieldName} - {minimum}");
          if (context.Function.GetValue(context.CaseFieldName) is int value && value != default && value < minimum)
          {
               context.Function.SetValue(context.CaseFieldName, Math.Max(minimum, value));
          }
     }

    [ActionParameter("maximum", "The maximum value",
        valueTypes: new[] { IntType, DecimalType, DateType })]
     [CaseBuildAction("MaxLimit", "My max limit function")]
     public void MaxLimit(CaseChangeActionContext context, object maximum) 
     {
          //context.Function.LogWarning($"MyNamespace.MaxLimit: {context.CaseFieldName} - {maximum}");
        var valueType = context.Function.GetValueType(context.CaseFieldName).ToActionValueType();
        if (valueType == ActionValueType.Integer)
        {
            var maximumValue = GetActionValue<int?>(context, maximum);
            if (maximumValue?.ResolvedValue == null || !maximumValue.IsFulfilled)
            {
                return;
            }
            var sourceValue = GetActionValue<int>(context);
            if (sourceValue != null && sourceValue.ResolvedValue > maximumValue.ResolvedValue)
            {
                context.Function.SetValue(context.CaseFieldName, maximumValue.ResolvedValue);
            }
        }
        else if (valueType == ActionValueType.Decimal)
        {
            var maximumValue = GetActionValue<decimal?>(context, maximum);
            if (maximumValue?.ResolvedValue == null || !maximumValue.IsFulfilled)
            {
                return;
            }
            var sourceValue = GetActionValue<decimal>(context);
            if (sourceValue != null && sourceValue.ResolvedValue > maximumValue.ResolvedValue)
            {
                context.Function.SetValue(context.CaseFieldName, maximumValue.ResolvedValue);
            }
        }
        else if (valueType == ActionValueType.DateTime)
        {
            var maximumValue = GetActionValue<DateTime?>(context, maximum);
            if (maximumValue?.ResolvedValue == null || !maximumValue.IsFulfilled)
            {
                return;
            }
            var sourceValue = GetActionValue<DateTime>(context);
            if (sourceValue != null && sourceValue.ResolvedValue != maximumValue.ResolvedValue)
            {
                context.Function.SetValue(context.CaseFieldName, maximumValue.ResolvedValue);
            }
        }

     }

     [CaseValidateAction("MyRule()", "My custom rule")]
     public void MaxLength(CaseChangeActionContext context) 
     {
          if (context.Function.GetValue(context.CaseFieldName) is string value && value.Length > 3)
          {
               context.AddIssue($"Maximum length is 3: {value}");
          }
     }
}
