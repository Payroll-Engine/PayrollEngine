using System;
using PayrollEngine.Client.Scripting.Function;

/// <summary>
/// Extension methods for the March clause (Märzklausel):
/// a one-time payment made in Q1 is checked against the remaining annual
/// contribution ceiling (BBG) of the previous year. If the payment exceeds
/// the remainder, a retro payrun for December of the previous year must be
/// scheduled so that social insurance is recalculated with the bonus
/// attributed to that year.
///
/// Retro scheduling pattern:
///   In production, call ScheduleRetroPayrun() directly in the valueExpression:
///     if (!IsRetroPayrun &amp;&amp; this.NeedsMarchClauseRetro(90000m))
///         ScheduleRetroPayrun(new DateTime(PeriodStart.Year - 1, 12, 1));
///     return (decimal)CaseValue["AnnualBonus"];
///
///   In Exchange test imports, retro runs are driven by retroJobs in the YAML.
///   ScheduleRetroPayrun() must NOT be called during an Exchange import payrun
///   invocation — the scheduled job cannot start while the current job is still
///   running, causing a deadlock.
/// </summary>
public static class MarchClauseExtensions
{
    /// <summary>Returns true when the current period falls in Q1 (January–March).</summary>
    /// <param name="fn">The wage type value function providing period context.</param>
    public static bool IsMarchClausePeriod(this WageTypeValueFunction fn) =>
        fn.PeriodStart.Month >= 1 && fn.PeriodStart.Month <= 3;

    /// <summary>
    /// Returns the remaining BBG allowance for the employee:
    /// bbgLimit minus PreviousYearEarnings (employee case, Timeless).
    /// </summary>
    /// <param name="fn">The wage type value function providing case value access.</param>
    /// <param name="bbgLimit">The annual contribution ceiling (BBG) in the employee's currency.</param>
    public static decimal GetBbgRemainder(this WageTypeValueFunction fn, decimal bbgLimit)
    {
        var previousEarnings = (decimal)fn.CaseValue["PreviousYearEarnings"];
        return Math.Max(0m, bbgLimit - previousEarnings);
    }

    /// <summary>
    /// Returns true when the March clause retro must be triggered:
    /// bonus is positive, current period is Q1, and bonus exceeds the BBG remainder.
    /// The caller is responsible for scheduling the retro payrun.
    /// </summary>
    /// <param name="fn">The wage type value function providing case value access and period context.</param>
    /// <param name="bbgLimit">The annual contribution ceiling (BBG) in the employee's currency.</param>
    public static bool NeedsMarchClauseRetro(this WageTypeValueFunction fn, decimal bbgLimit)
    {
        var bonus = (decimal)fn.CaseValue["AnnualBonus"];
        return bonus > 0m
            && fn.IsMarchClausePeriod()
            && bonus > fn.GetBbgRemainder(bbgLimit);
    }

    /// <summary>
    /// Returns the annual bonus value.
    /// Pure calculation — does not schedule any retro payrun.
    /// Use NeedsMarchClauseRetro() to determine whether a retro must be triggered.
    /// </summary>
    /// <param name="fn">The wage type value function providing case value access.</param>
    /// <param name="bbgLimit">The annual contribution ceiling (BBG) in the employee's currency.</param>
    public static decimal GetMarchClauseBonus(this WageTypeValueFunction fn, decimal bbgLimit) =>
        (decimal)fn.CaseValue["AnnualBonus"];
}
