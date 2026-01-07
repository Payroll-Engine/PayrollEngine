using System;

#pragma warning disable IDE0130
namespace PayrollEngine.Client.Scripting.Function;
#pragma warning restore IDE0130

public partial class CaseValidateFunction
{
    // from PayrollEngine.Client.Scripting.Function.CaseValidateFunction.cs
    public void LogInformation(string message, string error = null, string comment = null)
        => throw new NotImplementedException();
    public void LogError(string message, string error = null, string comment = null)
        => throw new NotImplementedException();

    public void AddCaseIssue(string message)
        => throw new NotImplementedException();
    public void AddCaseFieldIssue(string caseFieldName, string message)
        => throw new NotImplementedException();
    public void AddCaseAttributeIssue(string attributeName, params object[] parameters)
        => throw new NotImplementedException();
    public void AddFieldAttributeIssue(string caseFieldName, string attributeName, params object[] parameters) =>
        throw new NotImplementedException();
}
