# Payroll Engine — Release Notes

## v1.2.0 - Unreleased

### Highlights

* **Pay date** — every payrun job has a pay date: period end plus the calendar `PayDateOffset`, or an explicit override per job (e.g. early payment before a holiday). The pay date is stored on the payrun job and on all payroll results
* **Regulation date by pay date** — when the pay date differs from the period end date, regulations, case fields, and lookups are resolved at the pay date; tax years that follow the pay date (e.g. a December period paid in January) are calculated with the regulation version of the pay date
* **Calendar cycle assignment** — the calendar `CycleAssignment` selects the date that assigns a period to the cycle (tax year) and to the regulation version: `PayDate` (default, e.g. US, UK, AU — a December period paid in January belongs to the next year) or `PeriodEnd` (e.g. DE, AT, CH — the period belongs to the year of its end, regardless of the pay date). Cycle start, year-to-date consolidation, and cycle result queries follow the assignment
* **Anchored weekly and bi-weekly periods** — the calendar `PeriodAnchorDate` produces continuous 7-day and 14-day periods across year boundaries; bi-weekly periods no longer restart at the beginning of the year or overlap in years with 53 weeks. Calendars without an anchor keep the previous week-of-year behavior
* **Signed webhooks** — a webhook with a secret signs its requests (`X-PE-Timestamp`, `X-PE-Signature`, HMAC-SHA256); scripting webhook responses must be signed (`X-PE-Response-Signature`), otherwise the payrun job aborts. The secret is write-only and encrypted at rest

### Backend

**Database Update required** — the backend requires schema **1.2.0** (minimum schema version **1.2.0**) and refuses to start against an older schema. The **Update-Model** scripts migrate schema **1.1.0 → 1.2.0** for SQL Server, MySQL, and — for the first time — PostgreSQL (`Update-Model.pg.sql`). The update adds the new columns and fills existing data: `PayrunJob.PayDate` is set to the period end date, and the result pay date is taken from its payrun job.

**New Features**

* **Calendar** — `PeriodAnchorDate` (anchor of continuous weekly and bi-weekly periods) and `PayDateOffset` (pay date = period end + offset days)
* **Payrun job pay date** — `PayrunJobInvocation.PayDate` (optional override) and `PayrunJob.PayDate`; without override the pay date is calculated from the payroll calendar
* **Retro payruns** — retro jobs reuse the pay date of the original payrun job of the retro period
* **Results** — `PayDate` on wage type results, wage type custom results, collector results, collector custom results, and payrun results, including consolidated result queries
* **Scripting** — `PayDate`, `PayDateYear`, and `GetPayDate(periodMoment)` in all payroll functions
* **Calendar cycle assignment** — `Calendar.CycleAssignment` (`PayDate`, `PeriodEnd`; default `PayDate`). With `PayDate`, the payrun job cycle is taken from the job pay date, and the year-to-date consolidation includes the periods paid within the cycle up to the current pay date, using the pay dates of the payrun jobs (early and late payments, pay date overrides). With `PeriodEnd`, the cycle and the regulation date are taken from the period end
* **Scripting calendar** — `CycleTimeUnit`, `PeriodTimeUnit` and `TimeMap` in all payroll functions; the `CalendarTimeUnit` value is the number of periods per year (e.g. `Week` 52, `BiWeek` 26, `SemiMonth` 24, `CalendarMonth` 12); `TimeMap` lets a regulation guard reject a calendar whose `Cycle` time map would divide calendar period case values it already annualizes
* **Scripting cycle** — `CycleDate`, `GetCyclePeriodRange(offset)` in all payroll functions; `GetConsolidatedPeriodStarts(periodMoment)` in payrun functions. Cycle result queries (`GetWageTypeCycleResults`, `GetCollectorCycleResults`, previous cycle values) use the period range of the cycle
* **Calendar validation** — the `PeriodAnchorDate` and the `CycleAssignment` of a calendar cannot be changed once payrun jobs exist for the calendar (division or employee calendar); the update is rejected with `400 Bad Request`
* **Signed webhooks** — `Webhook.Secret` (write-only; on update omitted keeps, empty removes, a value replaces) and read-only `Webhook.Signed`. Request signature `v1=` + HMAC-SHA256 over `{timestamp}.{body}`; response signature for scripting webhooks over `{timestamp}.{requestSignature}.{responseBody}`. A secret that cannot be read stops the dispatch, nothing is sent unsigned. Exchange exports contain `signed`, never the secret — set the secret again after an import
* **Webhook tracking mode** — `PayrollServerConfiguration:WebhookTracking` (`None`, `Notification`, `All`)
* **Data protection keys** — the secret is encrypted with ASP.NET Core data protection; `PayrollServerConfiguration:DataProtectionKeyPath` sets the persistent key ring location (required for containers and multiple instances; lost keys require setting the secrets again)
* **Webhook performance** — tenant and user are loaded once per dispatched message instead of once per webhook; scripting webhook calls (`InvokeWebhook`) query the webhook of the action once per payrun job instead of once per call

**Behavior Change**

* **Webhook tracking** — the setting `PayrollServerConfiguration:WebhookTracking` (`None`, `Notification`, `All`; default `Notification`) controls tracking. Notification webhooks (case change added, payrun job process/finish, task change) are tracked as webhook messages with response status and message. Scripting webhook calls (`InvokeWebhook`) are tracked only with `All`
* **Scripting webhook connection error** — an unreachable receiver or a failed response status of a scripting webhook aborts the payrun job with an exception, instead of returning the error text or an empty value to the script
* **Removed webhook actions** — the never-triggered actions `PayrunFunctionRequest` and `ReportFunctionRequest` are removed; script webhook calls always use `CaseFunctionRequest`. The database update deletes existing webhooks with these actions; imports using them are rejected
* **Payroll validation** — the payrun validates the payroll regulations at the regulation date (period end, or pay date when it differs) instead of the period start, consistent with the payrun processing

**Bug Fixes**

* **Retro detection** — a payrun job invocation with a period start within the period (e.g. the 5th of a bi-weekly period) did not trigger retro jobs: the retro date was taken from the running job itself. The previous job is now determined by the calendar period start

**Existing calendars** — calendars without `CycleAssignment` use `PayDate`. Without `PayDateOffset` the pay date is the period end date, so cycles and regulation dates of existing payrolls remain unchanged.

**Database**

* New columns: `Calendar.PeriodAnchorDate`, `Calendar.PayDateOffset`, `Calendar.CycleAssignment`, `PayrunJob.PayDate`, and `PayDate` in `WageTypeResult`, `WageTypeCustomResult`, `CollectorResult`, `CollectorCustomResult`, and `PayrunResult`
* New column `Webhook.Secret` (encrypted secret, nullable)
* Webhooks with the removed actions `PayrunFunctionRequest` (20) and `ReportFunctionRequest` (30) are deleted
* PostgreSQL result functions return `PayDate` as the last column; the update script recreates the affected functions

### WebApp

**New Features**

* **Calendar editor** — pay date offset, period anchor date, and cycle assignment fields; the period anchor date and the cycle assignment are read-only once payrun jobs exist for the calendar, and a hint is shown when the anchor weekday differs from the first day of week
* **Payrun jobs** — optional pay date override when starting a payrun job; pay date column in the payrun job history
* **Webhooks** — write-only secret field (with remove option and visibility toggle) and a `Signed` column
* New labels in all localizations

**Changes**

* **Excel download** — uses the Document Excel export; the direct NPOI reference is removed

### Docker

* The compose files keep the data protection keys in the volume `backend-keys`; `docker-compose down -v` removes it together with the database (see `DOCKER.md`)

### PayrollConsole

* Load test commands (`LoadTestGenerate`, `PayrunLoadTest`) carry over the pay date of the invocation template
* Exchange import and export include the new calendar and payrun job fields (`PayrollEngine.Exchange.schema.json` updated)
* **Excel** — Excel imports (`RegulationExcelImport`, `CaseChangeExcelImport`) and the payrun load test Excel report are based on [ClosedXML](https://github.com/ClosedXML/ClosedXML) (MIT); NPOI is no longer used
* **Excel import dates** — a numeric cell is read as date when its number format is a date format; rows are read up to the last used row, rows after empty rows are no longer skipped
* **Lex commands** — `LexCheck`, `LexSnapshot` and `LexVerifySource` read spreadsheet sources with the built-in Lex reader

### Libraries

* **Core** — `CalendarCycleAssignment` enum; `WebhookAction.PayrunFunctionRequest` and `ReportFunctionRequest` removed (breaking change)
* **Client.Core** — `Webhook.Secret` and `Webhook.Signed` (exchange schema `secret`, `signed`)
* **Client.Core** — `Calendar.PeriodAnchorDate`, `Calendar.PayDateOffset`, `Calendar.CycleAssignment`, `PayrunJobInvocation.PayDate`, `PayrunJob.PayDate`, and `PayDate` on wage type, collector, and payrun results
* **Client.Core (fix)** — console error output failed with "The handle is invalid" on redirected output (CI, scripts), hiding the original error
* **Client.Scripting** — `IPayrollRuntime.PayDate`, `GetPayDate()`, `CycleDate`, `GetCyclePeriodStart()`, `CycleTimeUnit`, `PeriodTimeUnit`, and `TimeMap`; `IPayrunRuntime.GetConsolidatedPeriodStarts()`; `PayrollFunction.PayDate`, `PayDateYear`, `GetPayDate()`, `CycleDate`, `GetCyclePeriodRange()`, `CycleTimeUnit`, `PeriodTimeUnit`, and `TimeMap`; `PayrunFunction.GetConsolidatedPeriodStarts()`; enums `CalendarTimeUnit` and `CalendarTimeMap`
* **Client.Scripting (fix)** — `PayrollFunction.PeriodsInCycle` returned a wrong period count (the negative start offset was subtracted)
* **Client.Scripting** — `CycleStartOffset`, `CycleEndOffset`, `FirstCyclePeriod`, and `LastCyclePeriod` are based on the first period of the cycle according to the calendar cycle assignment
* **Client.Services** — local script runtime calculates the pay date, the cycle date, the cycle periods, and the calendar time units from the payroll calendar
* **Client.Services (fix)** — `CalendarExtensions.IsWorkDay` evaluated Tuesday against the Thursday work day setting
* **Client.Test** — payrun preview test result carries the invocation pay date
* **Document** — Excel export (`ExcelMergeAsync`) is based on [ClosedXML](https://github.com/ClosedXML/ClosedXML) (MIT); NPOI is no longer used. The public API exposes no Excel library types: the extension classes `CellExtensions` and `WorkbookExtensions` are removed
* **Lex** — built-in spreadsheet reader for `.xls`, `.xlsx` and `.xlsb` source documents based on [ExcelDataReader](https://github.com/ExcelDataReader/ExcelDataReader) (MIT): one section per sheet, numbers in invariant format, dates as serial numbers, at most 5000 rows per sheet. Live sources are also detected by content type. Readers passed to `SourceDocument` and `UrlChecker` override the built-in readers
* **Core, Serilog** — version alignment

### Tests

* **Backend unit tests** — anchored weekly and bi-weekly periods (year change, before anchor, 53-week year), pay date offset, regulation date, and cycle assignment (job cycle, cycle period start, year-to-date periods with early and late payments)
* **PayDate.Test** — payrun test for anchored bi-weekly periods, pay date offset and override, cycle assignment by pay date and by period end (cycle year, year to date, cycle periods, regulation selection across the year change), and retro jobs with the pay date of the original job
* **Webhook unit tests** — dispatch, signature, response verification (`Domain.Application.Tests`)
* **Webhook.Test** — receiver and runner for unsigned and signed webhooks (`Tests/Webhook.Test`, not part of `Test.All`)
* **Test-DbProviders.ps1** — runs the platform tests and examples against SQL Server, MySQL, and PostgreSQL, for new databases and for the update from the previous release (`devops/scripts`)

No breaking change — REST API and Scripting API changes are additive. The database schema update to 1.2.0 is required. The Document library removes the Excel extension classes `CellExtensions` and `WorkbookExtensions`; use `IDocumentService.ExcelMergeAsync` for Excel export.

---

## Docker Images (Linux)

| App | Version | Pull Command |
|-----|---------|-------------|
| PayrollEngine.Backend | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.backend:1.2.0` |
| PayrollEngine.PayrollConsole | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:1.2.0` |
| PayrollEngine.WebApp | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.webapp:1.2.0` |
| PayrollEngine.Mcp.Server | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.mcp.server:1.1.0` |
