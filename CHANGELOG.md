# Changelog

All notable changes to the Payroll Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> Previous release notes for versions `0.6.x` through `0.9.0-beta17` are
> available in the [GitHub Releases](https://github.com/Payroll-Engine/PayrollEngine/releases)
> and the [Wiki Releases](https://github.com/Payroll-Engine/PayrollEngine/wiki/Releases) page.

> **For maintainers:** The `Release-Changelog.ps1` script automatically
> replaces `[Unreleased]` with `[{version}] - {date}` and inserts a new
> empty `[Unreleased]` block on each release. Do not manually rename this
> section — edit `RELEASE_NOTES.md` instead.

---

<!-- UNRELEASED-START -->
## [Unreleased]

### Added

#### CI/CD
- Orchestrated release pipeline with wave-based build ordering
- Single-click release for all libraries and applications via GitHub Actions
- Version guard preventing accidental overwrites of existing releases, packages, and tags
- `Directory.Build.props` auto-updated, committed, and tagged by the workflow
- Dry-run mode for pipeline testing without side effects
- `RELEASE_NOTES.md` as single source for release text (umbrella release + wiki)
- New `ci.yml` workflow for build and test on pull requests and pushes to `main`
- New `devops/scripts` with release preparation tooling:
  - `Update-BreakingChanges.ps1` — automated breaking change detection across REST API, Backend, Scripting, and Client Services surfaces
  - `Release-Changelog.ps1` — cross-repo changelog collection with conventional commit parsing
  - `Update-CommitMessage.ps1` — pre-fills Git commit message from `RELEASE_NOTES.md` for Visual Studio

#### NuGet
- GitHub Packages as primary NuGet source for all `PayrollEngine.*` packages
- New `nuget.config` with package source mapping (`PayrollEngine.*` → GitHub Packages, `*` → NuGet.org)
- Dedicated sync workflow for selective NuGet.org publishing

#### Docker
- Automated Linux container builds for Backend, PayrollConsole, and WebApp
- Images published to `ghcr.io/payroll-engine/*`
- Pre-release images skip the `:latest` tag

#### Release Assets
- `swagger.json` auto-generated from Backend via Swashbuckle CLI, attached to Backend and umbrella release

#### Backend
- Payrun job preview endpoint (`POST .../payruns/jobs/preview`) — synchronous single-employee calculation without persisting results, returns `PayrollResultSet`
- Asynchronous payrun job processing with background queue (`PayrunJobQueue`, `PayrunJobWorkerService`)
- Configurable parallel employee processing (`MaxParallelEmployees`): `off`, `half`, `max`, `-1`, `1–N`
- Employee processing timing logs (`LogEmployeeTiming`) — per-employee duration and summary at Information level
- Bulk employee creation endpoint (`POST .../employees/bulk`) using `SqlBulkCopy` in 5,000-item chunks
- Retro payrun period limit (`MaxRetroPayrunPeriods`, default: `0`/unlimited)
- CORS configuration (`AllowedOrigins`, `AllowedMethods`, `AllowedHeaders`, `AllowCredentials`, `PreflightMaxAgeSeconds`) — inactive by default
- Rate limiting with global policy and dedicated payrun job start policy (`PermitLimit`, `WindowSeconds`) — inactive by default
- Configurable authentication (`None`, `ApiKey`, `OAuth`) with startup validation for OAuth authority and audience
- Explicit Swagger toggle (`EnableSwagger`, default: `false`)
- Per-category audit trail configuration (`AuditTrail.Script`, `.Lookup`, `.Input`, `.Payrun`, `.Report`)
- Script safety analysis (`ScriptSafetyAnalysis`) — static analysis rejecting banned APIs (`System.IO`, `System.Net`, `System.Diagnostics`, `System.Reflection`) — opt-in, default: `false`
- Configurable database collation check (`DbCollation`, default: `SQL_Latin1_General_CP1_CS_AS`) verified on startup
- New `PayrollServerConfiguration` for centralized server settings
- `ConsolidatedPayrunResultQuery` for consolidated payrun result queries
- Production `UseExceptionHandler` middleware for structured JSON error responses

#### Console
- Excel-based regulation import (`RegulationExcelImport`) supporting cases, case fields, case relations, collectors, wage types, lookups, lookup values, reports, report parameters, report templates, and scripts
- `PayrunEmployeePreviewTest` command for testing payrun preview without persisting results
- Built-in load test commands: `LoadTestGenerate`, `LoadTestSetup`, `LoadTestSetupCases`, `PayrunLoadTest` with CSV report (client + server timing)

#### Libraries
- `Client.Test`: `PayrunEmployeePreviewTestRunner` for preview-based payrun testing
- `Client.Core`: `NamespaceUpdateTool` for exchange namespace handling
- `Client.Core`: `AddCasesBulkAsync` in `IPayrollService` / `PayrollService`
- `Client.Core`: Updated `PayrunJobService` and `IPayrunJobService` for async payrun job support
- `Core`: `PayrunPreviewRetroException` with employee and retro date context

### Changed

- General: overall refactoring with Claude (Opus 4.6)
- General: updated exchange schema (`PayrollEngine.Exchange.schema.json`)
- Backend: updated database scripts for schema version `0.9.6`
- Backend: `PayrunJobInvocation` refactored from id-based to name/identifier-based references — `PayrunName` and `UserIdentifier` are now required fields **breaking change**
- Backend: `POST .../payruns/jobs` now returns HTTP `202 Accepted` with `Location` header instead of `201 Created` **breaking change**
- Client.Core: ownership pattern for `HttpClient` disposal in `PayrollHttpClient`
- Client.Core: updated collector and wage type result models with custom result properties
- Core: replaced SHA1 with SHA256 in `HashSaltExtensions` with constant-time comparison to prevent timing attacks
- Core: added regex timeout in `UserPassword.IsValid` to prevent ReDoS attacks
- Core: changed retro pay mode enum order

### Fixed

#### Backend
- Inverted slot filter logic in `GetCaseValuesAsync` — values matching the requested slot were excluded instead of kept
- `NullReferenceException` in timeless case value path
- Sort lookup values by `RangeValue` in `BuildRangeBrackets`
- Calculator cache key now includes culture, preventing wrong calculator for same-calendar employees with different cultures (e.g. `de-CH` vs `fr-CH`)
- Deterministic culture fallback in `CalculateEmployeeAsync` changed from `CultureInfo.CurrentCulture.Name` to `en-US`
- `CodeFactory.CodeFiles` race condition — replaced `Dictionary` with `ConcurrentDictionary`
- Thread-safe timer initialization in `AssemblyCache` to prevent duplicate timer leak
- Sync-over-async bridge in scripting layer — replaced `.Result` with `.ConfigureAwait(false).GetAwaiter().GetResult()`

#### Web Application
- SSL certificate validation bypass with config-controlled `AllowInsecureSsl` setting
- `HttpClient` singleton disposal in `BackendServiceBase`
- `NullReferenceException` in `SetupUserTasks` — reordered `LoginAsync` to set tenant first
- `TaskService` injection in `UserSession` changed from `[Inject]` attribute to constructor injection
- Enabled `UseHsts` in production pipeline

#### Client Services
- Inverted condition in `ReportParameterParser.ParseParametersAsync` preventing parameter resolution
- `GetContinuePeriods` loop termination checking immutable source period instead of current period
- `WeekPayrollCycle.GetPayrollPeriod` using `AddYears` instead of `AddDays` for week offset

#### Client Test
- Null reference in `PayrunTestRunnerBase` when actual wage type or collector result is missing
- Collector custom results using expected id instead of actual result id
- `ReportTestRunner` crash when `CustomTestFiles` is null
- `CleanupTenant` not resolving tenant by identifier when id is zero

#### Client Scripting
- `JsonElement` null handling in `Function.ChangeValueType` without unwrapping `Nullable` types
- Deep copy of tags and attributes in `CaseValue` copy constructor
- `Date.Tomorrow` and `Date.Yesterday` changed from `static readonly` to computed properties
- Off-by-one in `HasOverlapping` skipping first element in `DatePeriod` and `HourPeriod` extensions
- Period creation for open-ended date ranges in `PeriodValue` constructor
- Period-matching in `CasePayrollValue` modulo operator to prevent `IndexOutOfRangeException`

#### Client Core
- Inverted validation logic in `ExchangeImport` constructor
- Case relation duplicate detection using wrong property in `ExchangeMerge`
- Sort lookup values by `RangeValue` in `GetLookupRanges`

#### Core
- Double `CopyToAsync` and missing stream position reset in `StreamExtensions.WriteToFile`
- `TryGetCellValue` return value inconsistency in `DataTable`

### Removed

- `Client.Services`: `PayrunRuntimeBase.GetConsolidatedCollectorCustomResults` **breaking change**
- `Client.Services`: `PayrunRuntimeBase.GetConsolidatedCollectorResults` **breaking change**
- `Client.Services`: `PayrunRuntimeBase.GetConsolidatedWageTypeCustomResults` **breaking change**
- `Client.Services`: `PayrunRuntimeBase.GetConsolidatedWageTypeResults` **breaking change**
- `Client.Services`: `CaseController.GetCase` **breaking change**
- `Backend`: `PayrunId` and `UserId` properties from `PayrunJobInvocation` API and domain models **breaking change**

---

<!-- LINKS-START — managed by Release-Changelog.ps1, do not edit manually -->
[Unreleased]: https://github.com/Payroll-Engine/PayrollEngine/compare/main...HEAD
<!-- Example after a release:
[Unreleased]: https://github.com/Payroll-Engine/PayrollEngine/compare/v0.9.0...HEAD
[0.9.0]: https://github.com/Payroll-Engine/PayrollEngine/releases/tag/v0.9.0
-->
