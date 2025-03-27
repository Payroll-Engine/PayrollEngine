using System;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using PayrollEngine.Client.Scripting;
using PayrollEngine.Client.Scripting.Function;

// ReSharper disable once CheckNamespace

/// <summary>Timesheet wage calculator without custom implementations</summary>
public class TimesheetCalculator<TTimesheet> :
    TimesheetCalculator<TTimesheet, TimesheetPeriod, WorkTime, Employment>
    where TTimesheet : Timesheet, new();

/// <summary>Timesheet wage calculator</summary>
public class TimesheetCalculator<TTimesheet, TTimesheetPeriod, TWorkTime, TEmployment>
    where TTimesheet : Timesheet, new()
    where TTimesheetPeriod : TimesheetPeriod, new()
    where TWorkTime : WorkTime, new()
    where TEmployment : Employment, new()
{

    #region Local Types

    /// <summary>Wage day</summary>
    protected class WageDay
    {
        public WageTypeValueFunction Function { get; init; }
        public TTimesheet Timesheet { get; init; }
        public TEmployment Employment { get; init; }
        public TWorkTime WorkTime { get; init; }
        public DateTime Date => WorkTime.WorkTimeDate;

        public decimal GetRegularWorkHours(HourPeriod period)
        {
            var hours = WorkTime.WorkTimePeriod.IntersectHours(period);
            if (WorkTime.WorkTimeBreak > 0)
            {
                hours -= (WorkTime.WorkTimeBreak / 60);
            }
            return hours < 0 ? 0 : hours;
        }

        public decimal GetPeriodWorkHours(HourPeriod period) =>
            WorkTime.WorkTimePeriod.IntersectHours(period);
    }

    /// <summary>Timesheet period info</summary>
    private class TimesheetPeriodInfo
    {
        public int Order { get; init; }
        public PropertyInfo PeriodProperty { get; init; }
        public TTimesheetPeriod TimesheetPeriod { get; init; }
        public HourPeriod PeriodHours { get; set; }
    }

    #endregion

    #region Regular Wage

    /// <summary>Calculate regular wage</summary>
    public decimal RegularWage(WageTypeValueFunction function)
    {
        ArgumentNullException.ThrowIfNull(function);

        var wage = 0m;
        foreach (var day in CollectWageDays(function))
        {
            var period = GetTimesheetPeriods(day.Timesheet).FirstOrDefault(x => x.PeriodProperty == null);
            if (period != null)
            {
                wage += CalcRegularWage(day, period.PeriodHours);
            }
        }
        return wage;
    }

    /// <summary>Calculate regular wage</summary>
    /// <param name="day">Wage day</param>
    /// <param name="timesheetPeriod">Timesheet period</param>
    protected virtual decimal CalcRegularWage(WageDay day, HourPeriod timesheetPeriod)
    {
        var hours = day.GetRegularWorkHours(timesheetPeriod);
        if (hours <= 0 || day.Timesheet.RegularRate <= 0)
        {
            return 0;
        }

        // casual factor
        var casualFactor = day.Employment.CasualWorker ? 1m + day.Timesheet.CasualRateFactor : 1m;

        // regular period wage
        var wage = hours * day.Timesheet.RegularRate * casualFactor;

        // debug info
        day.Function.LogDebug($"Day {day.WorkTime.WorkTimeDate}: hours={hours}, wage={wage}, " +
                              $"rate={day.Timesheet.RegularRate}, casualFactor={casualFactor}");
        return wage;
    }

    #endregion

    #region Period Wage

    /// <summary>Calculate period wage</summary>
    /// <param name="function">Wage type value function</param>
    /// <param name="periodPropertyName">Calc period property name</param>
    public decimal PeriodWage(WageTypeValueFunction function, string periodPropertyName)
    {
        ArgumentNullException.ThrowIfNull(function);
        ArgumentException.ThrowIfNullOrWhiteSpace(periodPropertyName);

        var wage = 0m;
        foreach (var day in CollectWageDays(function))
        {
            var periods = GetTimesheetPeriods(day.Timesheet);
            if (!periods.Any())
            {
                continue;
            }

            // period wage
            var period = periods.FirstOrDefault(x => string.Equals(x.PeriodProperty?.Name, periodPropertyName));
            if (period != null)
            {
                wage += CalcPeriodWage(day, period.PeriodHours, period.TimesheetPeriod);
            }
        }
        return wage;
    }

    /// <summary>Calculate period wage</summary>
    /// <param name="day">Wage day</param>
    /// <param name="timesheetPeriod">Timesheet period</param>
    /// <param name="period">Timesheet period</param>
    protected virtual decimal CalcPeriodWage(WageDay day, HourPeriod timesheetPeriod,
        TTimesheetPeriod period)
    {
        var hours = day.GetPeriodWorkHours(timesheetPeriod);
        if (hours <= 0 || period.Factor <= 0)
        {
            return 0;
        }

        // casual factor
        var casualFactor = day.Employment.CasualWorker ? 1m + day.Timesheet.CasualRateFactor : 1m;

        // period wage
        var wage = day.Timesheet.RegularRate * casualFactor * hours * (1m + period.Factor);

        // debug info
        day.Function.LogDebug($"Day {day.WorkTime.WorkTimeDate}: hours={hours}, wage={wage}, " +
                              $"rate={day.Timesheet.RegularRate}, casualFactor={casualFactor}");

        return wage;
    }

    #endregion

    #region Core

    /// <summary>Get valid timesheet periods</summary>
    /// <param name="timesheet">Source timesheet</param>
    private List<TimesheetPeriodInfo> GetTimesheetPeriods(TTimesheet timesheet)
    {
        // collected periods, initializing with the regular period
        var periods = new List<TimesheetPeriodInfo>
        {
            new()
            {
                PeriodHours = new(timesheet.StartTime, timesheet.EndTime)
            }
        };

        // timesheet periods
        foreach (var propertyInfo in timesheet.GetType().GetProperties())
        {
            // period metadata
            var attribute = propertyInfo.GetCustomAttribute(typeof(TimesheetPeriodAttribute))
                as TimesheetPeriodAttribute;
            if (attribute == null ||
                propertyInfo.GetValue(timesheet) is not TTimesheetPeriod period ||
                !period.HasData())
            {
                continue;
            }
            periods.Add(new TimesheetPeriodInfo
            {
                Order = attribute.Order,
                PeriodProperty = propertyInfo,
                TimesheetPeriod = period
            });
        }
        if (periods.Count <= 1)
        {
            return periods;
        }

        // duplicate check
        var duplicate = periods.GroupBy(period => period.Order).FirstOrDefault(x => x.Count() > 1);
        if (duplicate != null)
        {
            throw new ScriptException($"Duplicated timesheet order: {duplicate.Key}");
        }

        // early period hours
        var earlyEnd = timesheet.StartTime;
        var earlyPeriods = periods.Where(x => x.Order < 0).OrderByDescending(x => x.Order);
        foreach (var period in earlyPeriods)
        {
            var earlyStart = earlyEnd - period.TimesheetPeriod.Duration;
            if (earlyStart < 0)
            {
                throw new ScriptException($"Early period {period.PeriodProperty.Name} is out of range");
            }
            period.PeriodHours = new HourPeriod(earlyStart, earlyEnd);
            // period start ist the end for the previous early period
            earlyEnd = earlyStart;
        }

        // late period hours
        var lateStart = timesheet.EndTime;
        var latePeriods = periods.Where(x => x.Order > 0).OrderBy(x => x.Order);
        foreach (var period in latePeriods)
        {
            var lateEnd = lateStart + period.TimesheetPeriod.Duration;
            if (lateEnd > (decimal)Timesheet.DayDuration.TotalHours)
            {
                throw new ScriptException($"Late period {period.PeriodProperty.Name} is out of range");
            }
            period.PeriodHours = new HourPeriod(lateStart, lateEnd);
            // period end ist the start for the next late period
            lateStart = lateEnd;
        }

        // remove empty periods and sort by order
        periods = periods.Where(x => !x.PeriodHours.IsEmpty)
            .OrderBy(x => x.Order)
            .ToList();

        return periods;
    }

    /// <summary>Collect wage days, based on the work time dates</summary>
    private List<WageDay> CollectWageDays(WageTypeValueFunction function)
    {
        var days = new List<WageDay>();

        // work dated
        var workDates = function.GetPeriodRawCaseValues(CaseObject.GetCaseFieldName<TWorkTime>(nameof(WorkTime.WorkTimeDate)));

        // period casual worker and timesheet values
        var employmentValues = function.GetCaseObjectValues<TEmployment>();
        var timesheetValues = function.GetCaseObjectValues<TTimesheet>();

        // period work times
        var periodWorkTimes = function.GetPeriodRawCaseObjects<TWorkTime>(workDates.Select(x => x.Created).ToList());

        // collect working days
        foreach (var workTimeDate in workDates)
        {
            var date = workTimeDate.Value.ToDateTime();
            var periodWorkTime = periodWorkTimes.FirstOrDefault(x => x.WorkTimeDate == date);
            if (periodWorkTime == null)
            {
                continue;
            }

            var day = new WageDay
            {
                Function = function,
                Employment = function.GetCaseObject<TEmployment>(employmentValues, date),
                Timesheet = function.GetCaseObject<TTimesheet>(timesheetValues, date),
                WorkTime = periodWorkTime
            };
            days.Add(day);
        }

        return days;
    }

    #endregion

}