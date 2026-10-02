# Payroll Engine — Release Notes

## v1.1.0 - Oct 2026

### Highlights

* **PostgreSQL provider** — PostgreSQL 14+ is supported as a third database provider next to SQL Server and MySQL (`PayrollServerConfiguration:DbProvider = Postgres`)
* **MCP Server** — new tools for case schema discovery, payrun statistics, lookup comparison, and payroll structure; optional HMAC-SHA256 response signing
* **Multi-arch Docker images** — Backend, WebApp, PayrollConsole, and MCP Server images are published for `linux/amd64` and `linux/arm64`
* **Exact `jobStatus` filter** — result queries match the requested payrun job status exactly; open Draft, Release, or Process jobs no longer leak into Complete or Forecast results
* **Regulation shares across versions** — a single `RegulationShare` grants access to all `ValidFrom` versions of a shared regulation
* **Payroll calendar periods** — corrected period stepping for biweekly, semi-monthly, bi-monthly, quarterly, and semi-yearly calendars in consolidated queries
* **MCP Division isolation** — employee and division tools enforce the configured division in Division isolation mode

### Backend

**Database Update recommended** — the backend runs against schema **1.0.0** (minimum schema version unchanged). The **Update-Model** scripts (SQL Server and MySQL) from schema **1.0.0 → 1.1.0** contain no table or index changes; they replace stored procedures and functions. The database fixes below (exact `jobStatus` filter, regulation share matching, MySQL shared regulation access check) take effect only after the update. PostgreSQL databases are created with `Create-Model.pg.sql` (schema 1.1.0); there is no PostgreSQL update script for this release.

**New Features**

* **PostgreSQL provider** — new `Persistence.Postgres` provider with dialect-specific query building, catalog-based stored routine invocation, typed bulk insert, `Create-Model.pg.sql`, and a Docker setup in `Database/docker-pg`
* **MySQL Docker setup** — `Database/docker-mysql` with a create scenario and an update scenario that migrates the previous release schema
* **Multi-arch Docker image** — the release workflow publishes `linux/amd64` and `linux/arm64`; arm64 hosts no longer require QEMU emulation (fixes [Backend#17](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/17))

**Bug Fixes**

* **`jobStatus` result filter** — the wage type, collector, and consolidated result procedures used a bitwise subset match (`JobStatus & @jobStatus = JobStatus`), which leaked Draft, Release, and Process jobs into Complete queries and Draft jobs into Forecast queries; open correction runs could override the last completed result. All providers now compare the status exactly (fixes [Backend#15](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/15))
* **Regulation share matching** — derived regulation queries resolved `RegulationShare` by the version-specific regulation ID. With several `ValidFrom` versions of a shared regulation, only the version referenced by the share was accessible, and lookups of the other versions silently failed. The share is now matched by regulation name
* **MySQL shared regulation access** — twelve `GetDerived*` procedures granted access via `SharedRegulation = 1` without checking `RegulationShare` and its isolation level; they now apply the same check as the other providers
* **Shared regulations by name** — `RegulationRepository`, `CaseRepository`, and `CaseFieldRepository` resolve regulations, cases, and case fields of shared regulations owned by another tenant (Exchange import, report sets, PayrollConsole `Report` command)
* **Payroll calendar periods** — `GetPayrollPeriod` advanced by the wrong step for five period types: biweekly, quarterly, and bi-monthly caused an infinite loop in consolidated result queries; semi-yearly and semi-monthly skipped periods. `GetConsolidatedPeriodStarts` additionally stops with a warning if a period does not advance
* **Case field namespace resolution** — case builder namespace resolution accepted the first regulation namespace even when the case field did not exist there, producing errors such as `unknown case field` in payrolls with multiple regulation layers
* **CaseValidate and CaseBuild scripts** — script runtime settings were created without the regulation namespace, so short case field names silently failed (fixes [Backend#14](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/14))
* **Collector custom results** — result date is now set on collector custom results; consolidated queries with an earlier evaluation date previously excluded them
* **Script assembly cache** — recovers from `FileLoadException` ("Assembly with same name is already loaded") and disposes orphaned tenant load contexts on cache update
* **Release workflow** — `swagger.json` generation and upload restored; new `skip_version_guard` input to re-run a release

**Behavior Change**

* **`jobStatus` filter** — combined status flags no longer match several job statuses at once; query each status separately

**Dependencies**

* Asp.Versioning.Mvc 10.2.1, Microsoft.AspNetCore.Authentication.JwtBearer 10.0.10, Swashbuckle.AspNetCore 10.2.3, Microsoft.Data.SqlClient 7.0.2, MySqlConnector 2.6.1, Microsoft.CodeAnalysis.Compilers 5.6.0

### WebApp

**Bug Fixes**

* **Lookup editor** — the `RangeMode` field was not registered, causing a silent render failure on save; the field and the `LookupRangeMode` labels are added to all localizations (fixes [WebApp#4](https://github.com/Payroll-Engine/PayrollEngine.WebApp/issues/4))
* **Localization** — key typo `Shared,Text` → `Shared.Text` in all languages (runtime lookup failure), corrected English base strings, `Action.MoveDown` typo
* **Arabic localization** — terminology review: standard terms for tenant, payroll, payrun, wage type, collector, lookup, slot, expression, script, parameter, cluster, culture, and forecast; remaining English terms translated

**Docker**

* Multi-arch image for `linux/amd64` and `linux/arm64`

### PayrollConsole

**New Features**

* **`LexSnapshot` command** — generates an immutable compliance snapshot (`snapshot.json`) from a `lex.json` source manifest; supports single path or recursive scan, automatic download from `sourceUrl`, `/dryrun` validation, and `/schema` output of the `lex.json` JSON Schema
* **`/OkOnFail` toggle** — test commands (`PayrunTest`, `PayrunEmployeeTest`, `PayrunEmployeePreviewTest`, `CaseTest`, `ReportTest`) continue through all files on failure and exit with `Ok`; failures are still logged

**Docker**

* Multi-arch image for `linux/amd64` and `linux/arm64`

**Dependencies**

* System.Security.Cryptography.Xml 10.0.10, Serilog.Settings.Configuration 10.0.1

### MCP Server

**New Features**

* **Mcp.Tools** — new read-only tools:
  * `get_available_cases` — script-evaluated case availability for Employee, Company, and Global cases
  * `get_payrun_statistics` — legal and forecast payrun counts and employee counts per tenant and optional division within a date range, including tenant, division, and database context
  * `query_lookups`, `get_lookup_values`, `compare_lookup_values` — attribute-based lookup discovery and cross-cycle comparison
  * `list_payroll_cases`, `list_payroll_collectors` — payroll structure, including collector-to-wage-type resolution
* **Response signing** — optional HMAC-SHA256 integrity envelope (algorithm, signature, UTC timestamp) for tool responses; configured via `McpServer:IntegrityKey` or the `PayrollIntegrityKey` environment variable. Responses are unchanged when no key is configured
* **Mcp.Core** — `SignWithIntegrity()` helper and `AdminService` factory in `ToolBase`

**Security Fix**

* **Division isolation** — `get_employee`, `get_employee_attribute`, `get_division`, and `get_division_attribute` did not enforce the configured division in Division isolation mode, allowing access to employees and divisions outside the division scope. No API surface change; other isolation levels are unaffected

**Docker**

* Multi-arch image for `linux/amd64` and `linux/arm64`

### Libraries

* **Client.Core** — `TenantService` and `RegulationShareService`: `SetAttributeAsync` and `DeleteAttributeAsync` called the collection route instead of the named-attribute route, causing 404 (fixes [Client.Core#1](https://github.com/Payroll-Engine/PayrollEngine.Client.Core/issues/1))
* **Document** — FastReport.OpenSource 2026.2.8, NPOI 2.8.1, System.Security.Cryptography.Xml 10.0.12 (security update)
* **Core, Serilog, Client.Scripting, Client.Test, Client.Services** — version alignment and dependency updates

### Docker

* **docker-compose.yml / docker-compose.ghcr.yml** — Swagger UI enabled via environment override; previously `/` and `/swagger` returned 404 (fixes [#12](https://github.com/Payroll-Engine/PayrollEngine/issues/12))

### Tests

* **JobStatusFilter.Test** — verifies exact `jobStatus` matching in wage type, collector, and consolidated result queries

### DevOps

* **NuGet Trusted Publishing** — `sync-nuget-org` uses OIDC-based `NuGet/login` instead of a long-lived API key

No breaking change — REST API surface is unchanged from v1.0.1.

---

## Docker Images (Linux)

| App | Version | Pull Command |
|-----|---------|-------------|
| PayrollEngine.Backend | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.backend:1.1.0` |
| PayrollEngine.PayrollConsole | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:1.1.0` |
| PayrollEngine.WebApp | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.webapp:1.1.0` |
| PayrollEngine.Mcp.Server | 1.1.0 | `docker pull ghcr.io/payroll-engine/payrollengine.mcp.server:1.1.0` |
