# Payroll Engine — Release Notes

## v1.2.0 - Unreleased

### Highlights

* **Pay date** — every payrun job has a pay date: period end plus the calendar `PayDateOffset`, or an explicit override per job (e.g. early payment before a holiday). The pay date is stored on the payrun job and on all payroll results
* **Regulation date by pay date** — when the pay date differs from the period end date, regulations, case fields, and lookups are resolved at the pay date; tax years that follow the pay date (e.g. a December period paid in January) are calculated with the regulation version of the pay date
* **Calendar cycle assignment** — the calendar `CycleAssignment` selects the date that assigns a period to the cycle (tax year) and to the regulation version: `PayDate` (default, e.g. US, UK, AU — a December period paid in January belongs to the next year) or `PeriodEnd` (e.g. DE, AT, CH — the period belongs to the year of its end, regardless of the pay date). Cycle start, year-to-date consolidation, and cycle result queries follow the assignment
* **Anchored weekly and bi-weekly periods** — the calendar `PeriodAnchorDate` produces continuous 7-day and 14-day periods across year boundaries; bi-weekly periods no longer restart at the beginning of the year or overlap in years with 53 weeks. Calendars without an anchor keep the previous week-of-year behavior

### Backend

**Database Update required** — the backend requires schema **1.2.0** (minimum schema version **1.2.0**) and refuses to start against an older schema. The **Update-Model** scripts migrate schema **1.1.0 → 1.2.0** for SQL Server, MySQL, and — for the first time — PostgreSQL (`Update-Model.pg.sql`). The update adds the new columns and fills existing data: `PayrunJob.PayDate` is set to the period end date, and the result pay date is taken from its payrun job.

**New Features**

* **Calendar** — `PeriodAnchorDate` (anchor of continuous weekly and bi-weekly periods) and `PayDateOffset` (pay date = period end + offset days)
* **Payrun job pay date** — `PayrunJobInvocation.PayDate` (optional override) and `PayrunJob.PayDate`; without override the pay date is calculated from the payroll calendar
* **Retro payruns** — retro jobs reuse the pay date of the original payrun job of the retro period
* **Results** — `PayDate` on wage type results, wage type custom results, collector results, collector custom results, and payrun results, including consolidated result queries
* **Scripting** — `PayDate`, `PayDateYear`, and `GetPayDate(periodMoment)` in all payroll functions
* **Calendar cycle assignment** — `Calendar.CycleAssignment` (`PayDate`, `PeriodEnd`; default `PayDate`). With `PayDate`, the payrun job cycle is taken from the job pay date, and the year-to-date consolidation includes the periods paid within the cycle up to the current pay date, using the pay dates of the payrun jobs (early and late payments, pay date overrides). With `PeriodEnd`, the cycle and the regulation date are taken from the period end
* **Scripting cycle** — `CycleDate`, `GetCyclePeriodRange(offset)` in all payroll functions; `GetConsolidatedPeriodStarts(periodMoment)` in payrun functions. Cycle result queries (`GetWageTypeCycleResults`, `GetCollectorCycleResults`, previous cycle values) use the period range of the cycle
* **Calendar validation** — the `PeriodAnchorDate` and the `CycleAssignment` of a calendar cannot be changed once payrun jobs exist for the calendar (division or employee calendar); the update is rejected with `400 Bad Request`

**Behavior Change**

* **Payroll validation** — the payrun validates the payroll regulations at the regulation date (period end, or pay date when it differs) instead of the period start, consistent with the payrun processing

**Bug Fixes**

* **Retro detection** — a payrun job invocation with a period start within the period (e.g. the 5th of a bi-weekly period) did not trigger retro jobs: the retro date was taken from the running job itself. The previous job is now determined by the calendar period start

**Existing calendars** — calendars without `CycleAssignment` use `PayDate`. Without `PayDateOffset` the pay date is the period end date, so cycles and regulation dates of existing payrolls remain unchanged.

**Database**

* New columns: `Calendar.PeriodAnchorDate`, `Calendar.PayDateOffset`, `Calendar.CycleAssignment`, `PayrunJob.PayDate`, and `PayDate` in `WageTypeResult`, `WageTypeCustomResult`, `CollectorResult`, `CollectorCustomResult`, and `PayrunResult`
* PostgreSQL result functions return `PayDate` as the last column; the update script recreates the affected functions

### WebApp

**New Features**

* **Calendar editor** — pay date offset, period anchor date, and cycle assignment fields; the period anchor date and the cycle assignment are read-only once payrun jobs exist for the calendar, and a hint is shown when the anchor weekday differs from the first day of week
* **Payrun jobs** — optional pay date override when starting a payrun job; pay date column in the payrun job history
* New labels in all localizations

### PayrollConsole

* Load test commands (`LoadTestGenerate`, `PayrunLoadTest`) carry over the pay date of the invocation template
* Exchange import and export include the new calendar and payrun job fields (`PayrollEngine.Exchange.schema.json` updated)

### Libraries

* **Core** — `CalendarCycleAssignment` enum
* **Client.Core** — `Calendar.PeriodAnchorDate`, `Calendar.PayDateOffset`, `Calendar.CycleAssignment`, `PayrunJobInvocation.PayDate`, `PayrunJob.PayDate`, and `PayDate` on wage type, collector, and payrun results
* **Client.Core (fix)** — console error output failed with "The handle is invalid" on redirected output (CI, scripts), hiding the original error
* **Client.Scripting** — `IPayrollRuntime.PayDate`, `GetPayDate()`, `CycleDate`, and `GetCyclePeriodStart()`; `IPayrunRuntime.GetConsolidatedPeriodStarts()`; `PayrollFunction.PayDate`, `PayDateYear`, `GetPayDate()`, `CycleDate`, and `GetCyclePeriodRange()`; `PayrunFunction.GetConsolidatedPeriodStarts()`
* **Client.Scripting (fix)** — `PayrollFunction.PeriodsInCycle` returned a wrong period count (the negative start offset was subtracted)
* **Client.Scripting** — `CycleStartOffset`, `CycleEndOffset`, `FirstCyclePeriod`, and `LastCyclePeriod` are based on the first period of the cycle according to the calendar cycle assignment
* **Client.Services** — local script runtime calculates the pay date, the cycle date, and the cycle periods from the payroll calendar
* **Client.Services (fix)** — `CalendarExtensions.IsWorkDay` evaluated Tuesday against the Thursday work day setting
* **Client.Test** — payrun preview test result carries the invocation pay date
* **Core, Serilog, Document** — version alignment

### Tests

* **Backend unit tests** — anchored weekly and bi-weekly periods (year change, before anchor, 53-week year), pay date offset, regulation date, and cycle assignment (job cycle, cycle period start, year-to-date periods with early and late payments)
* **PayDate.Test** — payrun test for anchored bi-weekly periods, pay date offset and override, cycle assignment by pay date and by period end (cycle year, year to date, cycle periods, regulation selection across the year change), and retro jobs with the pay date of the original job
* **Test-DbProviders.ps1** — runs the platform tests and examples against SQL Server, MySQL, and PostgreSQL, for new databases and for the update from the previous release (`devops/scripts`)

No breaking change — REST API and Scripting API changes are additive. The database schema update to 1.2.0 is required.

---

## Docker Images (Linux)

| App | Version | Pull Command |
|-----|---------|-------------|
| PayrollEngine.Backend | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.backend:1.2.0` |
| PayrollEngine.PayrollConsole | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:1.2.0` |
| PayrollEngine.WebApp | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.webapp:1.2.0` |
| PayrollEngine.Mcp.Server | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.mcp.server:1.1.0` |
