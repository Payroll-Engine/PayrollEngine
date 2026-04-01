### Bug Fixes

### Features

- [Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend)
  - `Payrun.RetroTimeType` (enum) replaced by `Payrun.RetroBackCycles` (int): `-1` = unlimited (default), `0` = current cycle only, `n` = n previous cycles **breaking change**
  - `PayrollResult` denormalized with business-key string fields: `PayrunName`, `PayrunJobName`, `EmployeeIdentifier`, `PayrollName`, `DivisionName` — enables archive restore idempotency and self-describing results (consistent with existing `CycleName`/`PeriodName` pattern)
  - New `POST /payruns/jobs/import` endpoint — imports `PayrunJobSet[]` (payrun job + result sets) into a tenant; Phase 1a resolves all references (Payrun, Division, User, Employee) by business-key names (`422` on failure); Phase 1b checks for duplicate payrun job names (`409` on conflict); Phase 2 inserts in a `TransactionScope` — payrun job first, then result sets with new job ID; full rollback on failure (use cases: archive restore, tenant migration, system migration, staging seeding)
  - OData `any()` lambda operator — filters on JSON collection columns (`List<string>`, `List<int>`, etc.) using correlated `EXISTS` sub-queries; supports scalar arrays and key/value object arrays
  - OData `in` operator — value-set filter (`field in (v1, v2, ...)`) mapped to SQL `WHERE col IN (...)`
  - Both operators are backend-aware: SQL Server uses `OPENJSON`, MySQL uses `JSON_TABLE`
  - MySQL support: `IDbContext.BuildCollectionFromRaw` abstracts the `OPENJSON` / `JSON_TABLE` difference
  - `TenantIsolationLevel` server-wide policy — new `TenantIsolationFilter` enforces cross-tenant HTTP access control on every request: `None` (transparent), `Consolidation` (report scripts only), `Read` (GET + ReadSemantic POST cross-tenant), `Write` (full cross-tenant, `Auth-Tenant` header forbidden). Configured in `appsettings.json`. See [Security](https://payrollengine.org/Concepts/Security/#tenantisolationlevel)
  - `RegulationShare.IsolationLevel` — new field controlling access granted to the consumer tenant: `Consolidation` (cross-tenant result access for report scripts, regulation not added as payroll layer) or `Write` (full payroll layer, default)
  - `Report.ReportIsolation` — new field on `Report`; exposed via `GetDerivedReports` to allow per-report access control aligned with `TenantIsolationLevel`

- [MCP Server](https://github.com/Payroll-Engine/PayrollEngine.Mcp.Server)
  - Division isolation: `list_employees` now pushes the division filter to the backend via `divisions/any(d: d eq 'DivisionName')` — eliminates client-side post-filtering

- [Mcp.Core](https://github.com/Payroll-Engine/PayrollEngine.Mcp.Core) *(new)*
  - Core infrastructure for building Payroll Engine MCP servers: isolation model (`MultiTenant`, `Tenant`, `Division`, `Employee`), role-based permission system (`HR`, `Payroll`, `Report`, `System`), `ToolBase` abstract base class with typed service factories, isolation-aware query helpers and resolver methods, `ToolRegistrar` for startup-time tool filtering by role and isolation level compatibility

- [Mcp.Tools](https://github.com/Payroll-Engine/PayrollEngine.Mcp.Tools) *(new)*
  - Complete set of read-only MCP tools built on `Mcp.Core`: 27 tools across HR, Payroll, Report and System roles; all tools are read-only by design (`get_employee_pay_preview` and `execute_payroll_report` execute calculations without persisting results)

- [Core](https://github.com/Payroll-Engine/PayrollEngine.Core)
  - `RetroTimeType` enum removed — replaced by `Payrun.RetroBackCycles` (int) **breaking change**

- [Client.Scripting](https://github.com/Payroll-Engine/PayrollEngine.Client.Scripting)
  - WageType and Collector temporal selectors in action syntax — new scope properties on `^$WageType` and `^$Collector` tokens: `.PrevPeriod`, `.NextPeriod`, `.Cycle`, `.PrevCycle`, `.NextCycle`; additionally `.RetroSum` for WageTypes (sum of retro corrections within the current cycle)
  - New `Calculation` action group — 15 standard payroll calculation actions on `PayrunFunction`: `AnnualProjection`, `CycleToPeriod`, `PeriodToCycle`, `RoundToFraction`, `CappedContribution`, `RateContribution`, `LookupRateContribution`, `PhaseOut`, `LinearPhaseOut`, `PhaseIn`, `ProRateByDays`, `InsuranceWage`, `D2Delta`, `MinMaxContribution`, `ContributionIfObligated`
  - New `GetConsolidatedWageTypeValue` and `GetConsolidatedCollectorValue` actions — period-offset based consolidation (e.g. `-11` for a 12-period rolling window)

- [Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole)
  - New `PayrunEmployeePreviewTest` command — executes an employee payrun preview (no persistence) and tests the results
  - New `InstallRegulationPackage` command — installs a regulation NuGet package (`.nupkg`) directly into a PE backend tenant. Supports local file paths, wildcards, and HTTP(S) URLs (e.g. GitHub Release assets). Features: version check, cross-tenant dependency check, ordered manifest-driven import, dry-run mode, and automatic temp cleanup.
  - `HttpGet`: optional second parameter writes response body to a file
  - `HttpPost` / `HttpPut`: `Content-Type` set to `application/json` (was `text/plain` → HTTP 415)
  - URL placeholder resolution in HTTP commands: `{tenant:X}`, `{user:X}`, `{division:X}`, `{employee:X}`, `{regulation:X}`, `{payroll:X}`, `{payrun:X}`, `{payrunJob:X}` resolved to numeric IDs at runtime

- [Tests](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Tests)
  - New `PayrunJobImport.Test` — full export → delete → import → verify cycle for `POST /payruns/jobs/import`

