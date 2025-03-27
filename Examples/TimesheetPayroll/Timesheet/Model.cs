using System;
using PayrollEngine.Client.Scripting;

// ReSharper disable once CheckNamespace

/// <summary>Timesheet</summary>
public class Timesheet : CaseObject
{
    /// <summary>Day duration</summary>
    public static TimeSpan DayDuration = TimeSpan.FromHours(24);

    /// <summary>Regular period start time</summary>
    public decimal StartTime { get; set; }
    /// <summary>Regular period end time</summary>
    public decimal EndTime { get; set; }
    /// <summary>Minimum work time</summary>
    public decimal MinWorkTime { get; set; }
    /// <summary>Maximum work time</summary>
    public decimal MaxWorkTime { get; set; }
    /// <summary>Minimum break time</summary>
    public decimal BreakMin { get; set; }
    /// <summary>Maximum break time</summary>
    public decimal BreakMax { get; set; }
    /// <summary>Regular hour rate</summary>
    public decimal RegularRate { get; set; }
    /// <summary>Casual worker factor to the regular rate</summary>
    public decimal CasualRateFactor { get; set; }
    /// <summary>Work time step in minutes</summary>
    public int WorkTimeStep { get; set; }

    /// <summary>Test for enabled break</summary>
    public bool BreakEnabled() =>
        BreakMax > 0;
}

/// <summary>Timesheet period</summary>
public class TimesheetPeriod : CaseObject
{
    /// <summary>Period duration</summary>
    public decimal Duration { get; set; }
    /// <summary>Period rate factor</summary>
    public decimal Factor { get; set; }

    /// <summary>Test if period has data</summary>
    public bool HasData() =>
        Duration > 0 && Factor != 0;
}

/// <summary>Timesheet period attribute</summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Property)]
public class TimesheetPeriodAttribute : CaseObjectAttribute
{
    /// <summary>Default constructor</summary>
    /// <param name="order">Period order: greater thane zero = early period, greater than zero = late period</param>
    /// <param name="ns">Period namespace</param>
    public TimesheetPeriodAttribute(int order, string ns) : base(ns)
    {
        if (order == 0)
        {
            throw new ArgumentException("Timesheet period order must be unique and not value", nameof(order));
        }
        ArgumentException.ThrowIfNullOrWhiteSpace(ns);
        Order = order;
    }

    /// <summary>Period order</summary>
    public int Order { get; }
}

/// <summary>Work time</summary>
public class WorkTime : CaseObject
{
    /// <summary>Work time date</summary>
    public DateTime WorkTimeDate { get; set; }
    /// <summary>Work time start hour</summary>
    public decimal WorkTimeStart { get; set; }
    /// <summary>Work time end hour</summary>
    public decimal WorkTimeEnd { get; set; }
    /// <summary>Work time break in minutes</summary>
    public decimal WorkTimeBreak { get; set; }

    /// <summary>Work time hours</summary>
    public virtual decimal WorkTimeHours =>
        WorkTimeEnd - WorkTimeStart - (WorkTimeBreak / 60m);

    /// <summary>Work time period (no case field)</summary>
    [CaseFieldIgnore]
    public HourPeriod WorkTimePeriod =>
        new(WorkTimeStart, WorkTimeEnd);
}

public class Employment : CaseObject
{
    /// <summary>Casual worker</summary>
    public bool CasualWorker { get; set; }
}
