# Payroll Engine — Release Notes

## v1.3.0 - Nov 2026

### Highlights

* **Regulator role for MCP** — the new MCP role `Regulator` works with the provenance manifests (`lex.json`) of data regulations: list manifests, read entries, check (development and release mode, optional URL check), verify snapshots and sources, validate. The tools need no backend connection, only read files below configured workspace folders and are off by default (`McpServer:Permissions:Regulator` = `None`), so existing deployments gain no file access after an update
* **Workspace isolation** — every path argument is resolved below the configured roots (`McpServer:Regulator:Roots`, `RepoMask`); parent segments, absolute paths outside the roots and link escapes are rejected
* **MCP server without backend** — `PayrollEngine.Mcp.Server` starts without a backend connection when only the Regulator role is granted; a startup error names the missing setting otherwise. `get_server_info` reports the Lex library version, the regulator mode and the backend mode
* **Lex library operations** — source verification (including the write rules for locations and automatic records), entry validation, attestation rules, snapshot, apply and rollover cycle are library operations; the console commands are thin wrappers with unchanged output and exit codes

### Lex

* `ManifestEditor`: update entries (content, legal reference, source URLs, quote, reference year, description, `documentRef`, `rangeValue`), add, update and remove exclusions, add, update and remove sources, remove entries; property order is kept. `RemoveVerification` removes the verification record of an entry and returns it; `EntryUpdate.InvalidatesVerification` tells whether an update requires removing the verification record
* Workspace read model: `ILexSource` with `WorkspaceLexSource` (manifests below a root folder and repository mask) returns manifest and entry summaries with sources, review rule, matching exclusions and snapshot state; `ManifestHash` is the content hash of `lex.json`
* Range lookups: `LexApply` sets the range value of a new row in a range lookup (`rangeMode` other than `None`): a key in the format `yyyy-MM-dd` yields the number `yyyyMMdd`, any other key needs the new entry property `rangeValue` (`PayrollEngine.Lex.schema.json`), otherwise the apply stops with `rangeValueMissing` and writes nothing. Existing rows are never recomputed. The check reports range rows without range value as `rangeValueMissing` (finding in release mode, new last CSV column)
* `Checker.CheckSources` has the optional parameters `vocabulary` (folder of additional language files) and `sources` (local verification already computed by the caller). **Binary breaking:** assemblies built against 1.2.0 that call `CheckSources` must be rebuilt; source code compiles unchanged
* Fix: the check of evidence tracked in git no longer hangs inside a host that communicates over stdio (for example an MCP server); the git query closes its input, reads its output concurrently and ends after 30 seconds
* Check report: warnings are listed once with the affected satellites; a missing `git` or a folder outside a repository is a warning, never a finding
* Extended vocabulary files
* `CheckResult.EvidenceVersioningChecked` (new): true when the check of evidence tracked in git ran; false when it was skipped (no `git`, or a folder outside a repository), in addition to the existing warning
* `Fetcher.FetchAsync` has a new overload with the parameter `targetGuard` (`FetchAsync(client, url, lexDirectory, fileName, overwrite, targetGuard)`, all parameters required, `targetGuard` may be null). The existing signature `FetchAsync(client, url, lexDirectory, fileName = null, overwrite = false)` stays as an overload: existing calls and assemblies built against an earlier version keep working without a rebuild (binary and source compatible)
* `Fetcher`: the manifest (`lex.json`) and the snapshot (`snapshot.json`) are no fetch targets. `Fetcher.IsReservedFileName` tests a name (case, trailing dots and spaces ignored); `FetchAsync` refuses a reserved explicit name before the request and a reserved name derived from the URL before writing, and, in the overload with `targetGuard`, checks the full target path before anything is written
* `Fetcher`: a reserved target is refused with the new `ReservedFileNameException`, a subclass of `ArgumentException` (parameter `fileName`, property `FileName`, message unchanged), so callers no longer depend on the message text. A target in the `.lex` folder that is a symbolic link resolving outside the real `.lex` folder, to the manifest or the snapshot, or to no existing file, is neither read nor written, with or without overwrite (`FetchTargetLinkException`, an `IOException` with the properties `FileName` and `ResolvedPath`); links in the path of the `.lex` folder itself are resolved first. Hard links are not detected

### Payroll Console

* Lex commands use the library operations; `LexAttest` with `ReviewedBy` records the second review (four-eyes) of existing manual records; usage texts updated
* The cycle determination of `LexRollover` is part of the library
* `LexFetch` refuses the manifest and the snapshot as target file name (exit code `6`, nothing is written)
* `LexAttest`: `VerifiedBy` defaults to the environment variable `PAYROLL_ENGINE_LEX_USER`; an explicit value wins, the default is never used for a review, and the output names the origin of the person
* `LexApply` and `LexCheck` support the range value of new range lookup rows (`rangeValue`, finding `rangeValueMissing`); the dry run of `LexApply` shows the range value per change
* `LexCheck /release` reads additional language files from `PAYROLL_ENGINE_LEX_VOCABULARY`, as `LexVerifySource` does

### MCP

* `PayrollEngine.Mcp.Core`: role `Regulator`, tool base without backend client (public API of existing tools unchanged), workspace context with startup validation (`McpServer:Regulator`: `Roots`, `RepoMask`, `AgentIdentities`, `Backend` = `None` (default) or `Read`; any other `Backend` value stops the start)
* `PayrollEngine.Mcp.Server`: the backend connection is required only for a backend role (`HR`, `Payroll`, `Report`, `System`) or `Regulator:Backend` = `Read`; `Permissions:Regulator` other than `None` requires at least one workspace root; a failed start exits with code `1`. The README documents the Regulator profile, also as container with the workspace mounted as volume
* `PayrollEngine.Mcp.Core`: extensible role model — a server defines own roles with `McpRoleDefinition` (name, applicable isolation levels, backend requirement); tool classes reference them with `[ToolRole("<Name>")]`; `McpPermissions.FromConfiguration(configuration, roles)` reads `McpServer:Permissions:<Name>` (default `None`); `ToolRegistrar.GetPermittedTypes(assembly, permissions, level, roles)` registers them. The built-in roles and all existing signatures are unchanged; a tool class whose role the server does not define is not registered
* `get_server_info` reports the permissions of the roles defined by the server (`customRoles`, empty without own roles)
* **Behavior change — startup errors instead of silent fallbacks:** an `McpServer:IsolationLevel` that is not `MultiTenant`, `Tenant`, `Division` or `Employee`, and a value under `McpServer:Permissions` that is not `None`, `Read` or `Write`, now stop the server at startup with a message that names the setting, the value and the allowed values. Before, a misspelled isolation level selected `MultiTenant` and a misspelled permission selected `None` without a message. A missing or empty setting behaves as before (`MultiTenant`; `None` for a key missing in an existing `Permissions` section; defaults for a missing section). Check the configuration of existing deployments before updating
* `McpPermissions.FromConfiguration` throws `InvalidOperationException` for an unknown permission text; the documentation of `IsolationContext.Permissions` names the actual defaults (`Read` for the backend roles, `None` for `Regulator`)
* `PayrollEngine.Mcp.Tools`: tool group `RegulatorTools` with `lex_list_manifests`, `lex_get_entry`, `lex_check`, `lex_verify_snapshot`, `lex_verify_source`, `lex_validate`; filters `onlyProblems`, `summaryOnly`, `countsOnly`, a `sizeWarning` for results above 32,000 characters and progress notifications; `THIRD-PARTY-NOTICES.md` added
* `PayrollEngine.AiContext`: the Regulator role and its read-only tools are described in the overview and MCP tools context

### Packages

All platform libraries are released as 1.3.0 (one version line).

### Apps

All apps are released as 1.3.0 (Backend, PayrollConsole, WebApp, Mcp.Server). Backend and WebApp contain no functional change: the REST API is unchanged, and the database schema stays at version 1.2.0 (no database update is required).

**Breaking changes** — REST API, Scripting API and database schema are unchanged. Breaking are:

* The MCP server stops at startup on an invalid `McpServer:IsolationLevel` or permission value instead of falling back silently (see [MCP](#mcp))
* `PayrollEngine.Lex`: `Checker.CheckSources` gains optional parameters; assemblies built against 1.2.0 that call it must be rebuilt

## v1.2.0 - Nov 2026

### Highlights

* **Lex — source-traced compliance values** — the new library `PayrollEngine.Lex` and nine Payroll Console commands trace every statutory value of a data regulation to its official source: a `lex.json` manifest with source, location, legal reference and verification record per value, frozen evidence files with a hash snapshot, automatic verification against the source documents, manual four-eyes attestation, transfer into the regulation lookups, consistency and release gate, and the rollover to the next cycle. Complete tariff tables are taken from the authority text file itself (fixed columns or tab-delimited, also inside a ZIP archive) and written as compressed lookup archives
* **Pay date** — every payrun job has a pay date: period end plus the calendar `PayDateOffset`, or an explicit override per job (e.g. early payment before a holiday). The pay date is stored on the payrun job and on all payroll results
* **Regulation date by pay date** — when the pay date differs from the period end date, regulations, case fields, and lookups are resolved at the pay date; tax years that follow the pay date (e.g. a December period paid in January) are calculated with the regulation version of the pay date
* **Calendar cycle assignment** — the calendar `CycleAssignment` selects the date that assigns a period to the cycle (tax year) and to the regulation version: `PayDate` (default, for tax systems taxing on receipt — a December period paid in January belongs to the next year) or `PeriodEnd` (for tax systems taxing by the period worked — the period belongs to the year of its end, regardless of the pay date). Cycle start, year-to-date consolidation, and cycle result queries follow the assignment
* **Anchored weekly and bi-weekly periods** — the calendar `PeriodAnchorDate` produces continuous 7-day and 14-day periods across year boundaries; bi-weekly periods no longer restart at the beginning of the year or overlap in years with 53 weeks. Calendars without an anchor keep the previous week-of-year behavior
* **Signed webhooks** — a webhook with a secret signs its requests (`X-PE-Timestamp`, `X-PE-Signature`, HMAC-SHA256); scripting webhook responses must be signed (`X-PE-Response-Signature`), otherwise the payrun job aborts. The secret is write-only and encrypted at rest
* **Isolated console extensions** — each Payroll Console extension lives in its own folder with an `extension.json` manifest (file hashes, required console version) and runs in its own load context; a failing extension affects neither the console nor other extensions

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
* **Lookup ranges of namespaced regulations** — `GetLookupRanges` did not apply the regulation namespace (unlike `GetLookup` and `GetRangeLookup`), so range lookups of namespaced regulations returned no brackets. Names that already carry the namespace are unchanged
* **Webhook message response** — `ResponseDate`, `ResponseStatus` and `ResponseMessage` of webhook messages were never stored, because the response arrives after the message is created; they are now written on update, a missing response date is stored as `NULL`

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
* **Lex commands** — complete command set for source-traced compliance values (see [Lex](https://payrollengine.org/Roles/Regulator/Lex/)):
  * `LexFetch` — download a source document unchanged into the `.lex` folder and declare it as evidence
  * `LexAdd` — add a value with source URLs, location, legal reference and evidence document
  * `LexVerifySource` — look up the numbers of every value in its sources, local evidence (`/local`, default) or live (`/live`); weak matches (short numbers, numbers in words, numbers next to another year) are rated *ambiguous*, `sourceQuote` anchors a value to a text passage, `/writelocations` and `/refreshlocations` write source locations and `auto` verification records, `/strict` returns exit code `6`
  * `LexAttest` — manual verification by a person against an evidence document, and the four-eyes review of sources with `FourEyes` rule
  * `LexSnapshot` — freeze values and evidence in `snapshot.json` (file hashes, value hash, text hash of every readable source URL); `/overwrite` regenerates, existing local copies are kept, build output is ignored
  * `LexVerify` — confirm that the snapshot is intact and current
  * `LexApply` — write the lex values into the lookup values of the regulation; open entries are skipped
  * `LexCheck` — coverage, value differences (all differing properties of a structured value), traceability fields, evidence tracked in git, `validFrom`, verification records, open entries, changed sources (`/checkurls`), Markdown and CSV report, `Root`/`RepoMask` for many repositories; `/release` is the release gate: precise locations, official main sources, no weak automatic matches, every value verifiable locally or live, zero values justified, no evidence file that backs no entry
  * `LexRollover` — create the data regulation of the next cycle from the payroll calendar of a tenant, with all entries open
* **Lex sources** — HTML, text, CSV, spreadsheets (`xls`, `xlsx`, `xlsb`, `ods`), PDF with text layer and form fields, `docx`, `odt`; several source URLs per value; language files for English, German, French, Spanish, Italian, Dutch and Portuguese in the `LexVocabulary` folder, further languages with `LexVerifySource Vocabulary:<folder>` or the environment variable `PAYROLL_ENGINE_LEX_VOCABULARY`
* **Lex text tables** — a lex entry with `contentFile` and `contentMap` takes a complete tariff table from the authority text file (fixed columns or tab-delimited); `archive.zip!entry.txt` reads a file of a ZIP archive in place. The map selects the columns and filters the record types:
  * `LexApply` replaces all values of the lookup when the table differs; a lookup file with lookups only is written as deterministic ZIP archive (`Regulation/Lookups.Name.json` → `Regulation/Lookups.Name.zip`), reported as `[ZIP] old -> new` with the hint to update the install files, the project file and the setup script; the summary counts the tables
  * `LexCheck` compares the table row by row (`table <lookup> +added, -removed, ~changed`)
  * `LexVerifySource` verifies a text table by file identity (the archive is declared with its source URLs and present in the `.lex` folder), reported as `file identity <n>`; no numbers are looked up
  * `LexSnapshot` hashes the table and its map; `LexRollover` renames the year of the archive reference (`tariffs-2026.zip!tariff-a26.txt` → `tariffs-2027.zip!tariff-a27.txt`)
* **LookupTextImport** — uses the text table classes of `PayrollEngine.Lex`; the mapping file accepts `filters` (line filters by column text, e.g. record types) and is validated before the import
* **Extensions (breaking change)** — assemblies placed directly into the `extensions` folder are no longer loaded. Each extension requires the folder `extensions/<Name>/` with an `extension.json` manifest (name, version, required console version, assemblies, SHA-256 file hashes). One load context per extension; `PayrollEngine.Client.Core`, `PayrollEngine.Core` and `PayrollEngine.Lex` are shared with the console. Core commands take precedence, a duplicate command name rejects the whole extension. See the migration guide in the PayrollConsole README
* **Extension commands** — `Extensions` lists the loaded extensions with status and commands; `ExtensionManifest` creates or updates the manifest with the hashes of all files; `Help` shows the source of a command (core or extension)
* **Command display** — all commands show their title and parameters (display level full)

### Libraries

**New**

* **Lex** — `PayrollEngine.Lex` (MIT, NuGet): manifest and snapshot model, JSON schema and validation, manifest editor that keeps unknown properties and order, fetcher, snapshot writer and verifier, checker with release gate, source verifier with rating of weak matches and year context (calendar and tax years, validity phrases, enactment citations), applier and rollover
  * Source readers detect the format from the content: HTML, text, CSV, PDF via [PdfPig](https://github.com/UglyToad/PdfPig) (Apache-2.0), spreadsheets `.xls`, `.xlsx`, `.xlsb` via [ExcelDataReader](https://github.com/ExcelDataReader/ExcelDataReader) (MIT) and `.ods`, `.docx`, `.odt`; one section per sheet, page or heading; readers passed by file extension override the built-in readers
  * Language files `{language}.json` (en, de, fr, es, it, nl, pt) in the `LexVocabulary` content folder; further languages from a folder given by the caller, selected per manifest with `languages`
  * Exclusion kinds `coverage`, `orphan`, `sourceLocation`, `autoVerification`, `derived`, `notApplicable`; entry properties `sourceUrls`, `sourceQuote`, `referenceYear`, `open`; source properties `review` (`SingleAuthor`, `FourEyes`) and `official`
  * Text tables: `TextTable` and `TextTableMap` (fixed columns and tab-delimited, line filters, implied decimals), `ContentSource` for files and ZIP archive entries, entry property `contentMap`, target kind `Table`; `RegulationReader` reads the JSON entries of `Regulation/*.zip`, the applier writes deterministic lookup archives (`ApplyResult.ReplacedFiles`), `ManifestVerifier.FileIdentityVerification`

**Features**

* **Core** — `CalendarCycleAssignment` enum; `WebhookAction.PayrunFunctionRequest` and `ReportFunctionRequest` removed (**breaking change**)
* **Client.Core** — `Calendar.PeriodAnchorDate`, `Calendar.PayDateOffset`, `Calendar.CycleAssignment`, `PayrunJobInvocation.PayDate`, `PayrunJob.PayDate`, and `PayDate` on wage type, collector, and payrun results
* **Client.Core** — `Webhook.Secret` and `Webhook.Signed` (exchange schema `secret`, `signed`)
* **Client.Core** — atomic command registration: `CommandManager.RegisterAssemblies(assemblies, origin)` registers all commands of an extension or none, `CommandOrigin` (core or extension), case-insensitive command names, `ExtensionApiVersion` 1.2 with `IsExtensionApiSupported`
* **Client.Scripting** — `IPayrollRuntime.PayDate`, `GetPayDate()`, `CycleDate`, `GetCyclePeriodStart()`, `CycleTimeUnit`, `PeriodTimeUnit`, and `TimeMap`; `IPayrunRuntime.GetConsolidatedPeriodStarts()`; `PayrollFunction.PayDate`, `PayDateYear`, `GetPayDate()`, `CycleDate`, `GetCyclePeriodRange()`, `CycleTimeUnit`, `PeriodTimeUnit`, and `TimeMap`; `PayrunFunction.GetConsolidatedPeriodStarts()`; enums `CalendarTimeUnit` and `CalendarTimeMap`
* **Client.Scripting** — `CycleStartOffset`, `CycleEndOffset`, `FirstCyclePeriod`, and `LastCyclePeriod` are based on the first period of the cycle according to the calendar cycle assignment
* **Client.Services** — local script runtime calculates the pay date, the cycle date, the cycle periods, and the calendar time units from the payroll calendar
* **Client.Services** — the API reference includes `PayrollEngine.Lex`
* **Client.Test** — payrun preview test result carries the invocation pay date
* **Document** — Excel export (`ExcelMergeAsync`) is based on [ClosedXML](https://github.com/ClosedXML/ClosedXML) (MIT); NPOI is no longer used. The public API exposes no Excel library types: the extension classes `CellExtensions` and `WorkbookExtensions` are removed
* **Core, Serilog** — version alignment

**Fixes**

* **Client.Core** — console error output failed with "The handle is invalid" on redirected output (CI, scripts), hiding the original error
* **Client.Core** — `FileReader` read a YAML entry of a ZIP archive with the archive name instead of the entry content; JSON entries were not affected
* **Client.Scripting** — `PayrollFunction.PeriodsInCycle` returned a wrong period count (the negative start offset was subtracted)
* **Client.Services** — `CalendarExtensions.IsWorkDay` evaluated Tuesday against the Thursday work day setting
* **Client.Test** — company case tests without employee failed with a `NullReferenceException`

**Build**

* **Third-party notices** — Backend, WebApp, PayrollConsole and MCP Server ship `THIRD-PARTY-NOTICES.md` in the build output; third-party libraries updated

### Tutorials

* **LexComplianceValues** — new client tutorial for `PayrollEngine.Lex`: the life cycle of a lex manifest on a fictitious data satellite — validate, add a value with source quote, verify against the local evidence, attest manually, snapshot, check, apply to the regulation lookups, release check with report, and rollover to the next cycle. Runs offline without backend
* **WebhookConsumer** — verifies signed webhook requests (`X-PE-Timestamp`, `X-PE-Signature`, max. request age) and signs the response of function requests (`X-PE-Response-Signature`); the secret is configured with `Webhook:Secret`, without secret the receiver works unsigned
* **PayrollConsoleExtension** — new extension layout: own extension folder with `extension.json` manifest (`Extension.cmd` builds the folder and creates the manifest with `ExtensionManifest`); references only the shared contract assembly `PayrollEngine.Client.Core`

### Tests

* **Backend unit tests** — anchored weekly and bi-weekly periods (year change, before anchor, 53-week year), pay date offset, regulation date, and cycle assignment (job cycle, cycle period start, year-to-date periods with early and late payments)
* **PayDate.Test** — payrun test for anchored bi-weekly periods, pay date offset and override, cycle assignment by pay date and by period end (cycle year, year to date, cycle periods, regulation selection across the year change), and retro jobs with the pay date of the original job
* **Webhook unit tests** — dispatch, signature, response verification (`Domain.Application.Tests`)
* **Webhook.Test** — receiver and runner for unsigned and signed webhooks (`Tests/Webhook.Test`, not part of `Test.All`)
* **Lex unit tests** — text tables: fixed and tab-delimited lines, filters, implied decimals, ZIP archive entries, snapshot and verification, table check and apply with deterministic archives, file identity, rollover of archive references
* **Client.Core unit tests** — new test project `Client.Core.Tests`: reading JSON and YAML entries of ZIP archives with `FileReader`
* **Test-DbProviders.ps1** — runs the platform tests and examples against SQL Server, MySQL, and PostgreSQL, for new databases and for the update from the previous release (`devops/scripts`)

**Breaking changes** — REST API and Scripting API changes are additive. The database schema update to 1.2.0 is required. Breaking are:

* Payroll Console extensions require their own folder with an `extension.json` manifest (`ExtensionManifest` creates it)
* `WebhookAction.PayrunFunctionRequest` and `ReportFunctionRequest` are removed; existing webhooks with these actions are deleted by the database update
* The Document library removes the Excel extension classes `CellExtensions` and `WorkbookExtensions`; use `IDocumentService.ExcelMergeAsync` for Excel export

---

## Docker Images (Linux)

| App | Version | Pull Command |
|-----|---------|-------------|
| PayrollEngine.Backend | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.backend:1.2.0` |
| PayrollEngine.PayrollConsole | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:1.2.0` |
| PayrollEngine.WebApp | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.webapp:1.2.0` |
| PayrollEngine.Mcp.Server | 1.2.0 | `docker pull ghcr.io/payroll-engine/payrollengine.mcp.server:1.2.0` |
