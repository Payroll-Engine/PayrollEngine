using System;
using System.Linq;
using System.Collections.Generic;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace
public static class WorkdayWages
{

    #region Early Morning

    public static decimal GetEarlyMorningWage(this WageTypeValueFunction function) =>
        CalcPeriodWage(
            function: function,
            periodFunc: GetEarlyMorningPeriod,
            useBreak: false,
            factorField: "EarlyMorningFactor");

    private static TimePeriod GetEarlyMorningPeriod(Workday day) =>
        new(0m, day.GetValue<decimal>("EarlyMorningDuration"));

    #endregion

    #region Regular

    public static decimal GetRegularWage(this WageTypeValueFunction function) =>
        CalcPeriodWage(
            function: function,
            periodFunc: GetRegularPeriod,
            useBreak: true);

    private static TimePeriod GetRegularPeriod(Workday day) =>
        TimePeriod.FromStart(
            start: GetEarlyMorningPeriod(day).End,
            hours: day.GetValue<decimal>("RegularWorkTime"));

    #endregion

    #region Overtime Low

    public static decimal GetOvertimeLowWage(this WageTypeValueFunction function) =>
        CalcPeriodWage(
            function: function,
            periodFunc: GetOvertimeLowPeriod,
            useBreak: false,
            factorField: "OvertimeLowFactor");

    private static TimePeriod GetOvertimeLowPeriod(Workday day) =>
        TimePeriod.FromStart(
            start: GetRegularPeriod(day).End,
            hours: day.GetValue<decimal>("OvertimeLowDuration"));

    #endregion

    #region Overtime High

    public static decimal GetOvertimeHighWage(this WageTypeValueFunction function) =>
        CalcPeriodWage(
            function: function,
            periodFunc: GetOvertimeHighPeriod,
            useBreak: false,
            factorField: "OvertimeHighFactor");

    private static TimePeriod GetOvertimeHighPeriod(Workday day) =>
        TimePeriod.FromStart(
            start: GetOvertimeLowPeriod(day).End,
            hours: day.GetValue<decimal>("OvertimeHighDuration"));

    #endregion

    #region Calculation

    private static readonly List<string> WorksheetFields =
    [
        "EarlyMorningDuration",
        "EarlyMorningFactor",
        "RegularWorkTime",
        "RegularRate",
        "CasualWorker",
        "CasualRateFactor",
        "OvertimeLowDuration",
        "OvertimeLowFactor",
        "OvertimeHighDuration",
        "OvertimeHighFactor",
    ];

    private class Workday
    {
        public DateTime Day { get; init; }
        public TimePeriod Period { get; init; }
        public decimal Break { get; init; }
        public Dictionary<string, object> Values { get; } = new();

        public T GetValue<T>(string key) =>
            Values.TryGetValue(key, out var caseValue) ? (T)caseValue : default;

        public decimal IntersectHours(TimePeriod intersect, bool useBreak)
        {
            var hours = Period.IntersectHours(intersect);
            return useBreak ? hours - (Break / 60) : hours;
        }
    }

    /// <summary>Calculate workdays wage</summary>
    private static decimal CalcPeriodWage(WageTypeValueFunction function,
        Func<Workday, TimePeriod> periodFunc, bool useBreak, string factorField = null) =>
        GetWorkdays(function).Sum(workday =>
            CalcDayWage(function, workday, periodFunc(workday), useBreak, factorField));

    /// <summary>Calculate the day wage</summary>
    private static decimal CalcDayWage(WageTypeValueFunction function, Workday day, 
        TimePeriod period,
        bool useBreak, string customFactorField = null)
    {
        var hours = day.IntersectHours(period, useBreak);
        var rate = day.GetValue<decimal>("RegularRate");
        if (hours <= 0 || rate == 0)
        {
            return 0;
        }

        // casual work factor
        var casualFactor = day.GetValue<bool>("CasualWorker") ?
            1m + day.GetValue<decimal>("CasualRateFactor") :
            1m;

        // custom factor
        var customFactor = !string.IsNullOrWhiteSpace(customFactorField) ?
            1m + day.GetValue<decimal>(customFactorField) :
            1m;

        // wage calculation
        var wage = hours * rate * casualFactor * customFactor;
        function.LogError($"Day wage {day.Day}: hours={hours}, wage={wage}, rate={rate}, casualFactor={casualFactor}, customFactor={casualFactor}");
        return wage;
    }

    /// <summary>
    /// Get working day including the worksheet settings per day
    /// </summary>
    /// <param name="function">Wage type value function</param>
    private static List<Workday> GetWorkdays(this WageTypeValueFunction function)
    {
        var workdays = new List<Workday>();

        // user values
        var startHours = function.GetPeriodRawCaseValues("WorkdayStart");
        var endHours = function.GetPeriodRawCaseValues("WorkdayEnd");
        var breaks = function.GetPeriodRawCaseValues("WorkdayBreak");
        if (startHours == null || endHours == null)
        {
            return workdays;
        }

        // worksheet
        var worksheetValues = new Dictionary<string, CasePayrollValue>();
        WorksheetFields.ForEach(x => worksheetValues.Add(x, function.GetCaseValue(x)));

        // collect working days
        foreach (var date in function.GetPeriodRawCaseValues("WorkdayDate"))
        {
            // start and end time
            var startHour = startHours.FirstOrDefault(x => x.Created == date.Created);
            var endHour = endHours.FirstOrDefault(x => x.Created == date.Created);
            if (startHour == null || endHour == null)
            {
                continue;
            }

            // workday
            var workday = new Workday
            {
                Day = date.Created,
                Period = new(startHour.Value, endHour.Value),
                Break = breaks.FirstOrDefault(x => x.Created == date.Created)?.Value
            };

            // worksheet
            foreach (var worksheetField in WorksheetFields
                         .Where(x => worksheetValues.ContainsKey(x)))
            {
                var dayValue = worksheetValues[worksheetField].PeriodValues
                    .FirstOrDefault(x => x.Period.IsWithin(date.Created))?.Value;
                if (dayValue != null)
                {
                    workday.Values[worksheetField] = dayValue;
                }
            }

            workdays.Add(workday);
        }
        return workdays;
    }

    #endregion

}