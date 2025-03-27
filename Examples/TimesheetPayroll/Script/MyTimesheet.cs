// ReSharper disable once CheckNamespace

public class MyTimesheet : Timesheet
{
    // case fields EarlyPeriodDuration and EarlyPeriodFactor
    [TimesheetPeriod(order: -1, ns: nameof(EarlyPeriod))]
    public TimesheetPeriod EarlyPeriod { get; } = new();

    // case fields LatePeriodLowDuration and LatePeriodLowFactor
    [TimesheetPeriod(order: +1, ns: nameof(LatePeriodLow))]
    public TimesheetPeriod LatePeriodLow { get; } = new();

    // case fields LatePeriodHighDuration and LatePeriodHighFactor
    [TimesheetPeriod(order: +2, ns: nameof(LatePeriodHigh))]
    public TimesheetPeriod LatePeriodHigh { get; } = new();

    // case field WeekendRateFactor
    public decimal WeekendRateFactor { get; set; }
}
