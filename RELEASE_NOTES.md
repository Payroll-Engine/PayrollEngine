### Bug Fixes

- [Client.Scripting](https://github.com/Payroll-Engine/PayrollEngine.Client.Scripting)
  - `CasePayrollValue`: fixed `FindMatchingPeriodValue` — added left-contains-right containment branch for retro payruns where a `Period` field (open-ended, `End=MaxValue`) appears on the left side of a binary operator and a `CalendarPeriod` field (trimmed end) on the right; previously the match returned `null` silently, causing all operators (`+`, `-`, `*`, `/`, `%`) to return `Empty` and the payrun to fail with `Missing results`

- [Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend)
  - Fixed concurrent assembly load collision in `AssemblyCache` — replaced lock-free double-entry with a proper lock to prevent race conditions during parallel payrun execution
  - Fixed `CaseValueRepositoryBase.GetPeriodCaseValuesAsync` period filter: changed `<` to `<=` for `Start` boundary, ensuring period-edge case values are included correctly

- [Web App](https://github.com/Payroll-Engine/PayrollEngine.WebApp)
  - Fixed report template encoding: changed ASCII to UTF-8 for XSL, XSD and FRX streams
  - Fixed payrun job workflow: Draft panel now displayed correctly after job start and on page reload

- [Examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples/ReportPayroll)
  - `CumulativeJournal`: fixed monthly result columns typed as decimal

### Features

- [Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend)
  - MySQL 8.4 LTS support via new `Persistence.MySql` provider (preview) — activate with `PayrollServerConfiguration__DbProvider=MySql`
  - `MaxParallelEmployees` default changed from sequential to auto (`ProcessorCount`) **breaking change** — use `off` or `-1` to restore sequential behavior
    - values: `0`/empty = auto, `off`/`-1` = sequential, `half` = ProcessorCount/2, `max` = ProcessorCount, `1`–`N` = explicit
  - `GET /api/admin/information` — new endpoint returning backend server diagnostics
    - **Assembly:** version, build date
    - **API:** version, name
    - **Authentication:** mode (`None` / `ApiKey` / `OAuth`); OAuth authority and audience (no secrets exposed)
    - **Database:** type, catalog name, server version, edition
    - **Runtime:** `MaxParallelEmployees` (resolved integer), `MaxRetroPayrunPeriods`, command/transaction/cache/webhook timeouts, `ScriptSafetyAnalysis`, audit trail flags, CORS origins, rate limiting policies
  - `IDbContext` extended with `GetDatabaseInformationAsync()` returning `DatabaseInformation` (type, name, catalog, version, edition)
  - `ReportIsolation` — new domain model and audit: report execution can be scoped to `None`, `Global`, `Company`, `Division`, or `Employee`

- [MCP Server](https://github.com/Payroll-Engine/PayrollEngine.McpServer) *(new, preview)*
  - AI agent interface for payroll data queries — read-only by design, no mutation operations
  - stdio transport via [Model Context Protocol](https://modelcontextprotocol.io/); compatible with Claude Desktop, GitHub Copilot, Cursor, and other MCP clients
  - **29 tools in 4 roles:**
    - `System` — tenant and user queries (`list_tenants`, `get_tenant`, `get_tenant_attribute`, `list_users`, `get_user`, `get_user_attribute`)
    - `HR` — employee master data, case values, and audit trail (`list_divisions`, `get_division`, `get_division_attribute`, `list_employees`, `get_employee`, `get_employee_attribute`, `list_employee_case_values`, `list_company_case_values`, `list_employee_case_changes`, `list_company_case_changes`)
    - `Regulation` — regulation definitions (`list_regulations`, `get_regulation`, `list_wage_types`, `list_lookups`, `list_lookup_values`)
    - `Payroll` — payroll execution and results (`list_payrolls`, `get_payroll`, `list_payruns`, `list_payrun_jobs`, `list_payroll_wage_types`, `list_payroll_result_values`, `get_consolidated_payroll_result`, `get_case_time_values`)
  - **Enrichment:** employee context (`identifier`, `firstName`, `lastName`) injected into all employee-scoped results; division name lookup in `list_payrun_jobs`; `list_payroll_result_values` fully denormalized
  - **`get_case_time_values`** supports three temporal perspectives: Historical, Current knowledge, Forecast
  - **Access control:** role-based permissions (`McpRole` / `McpPermission`) and isolation levels (`MultiTenant`, `Tenant`) configurable per deployment via `appsettings.json` or environment variables
  - Docker image available; `claude_desktop_config.json` example included

- [Core](https://github.com/Payroll-Engine/PayrollEngine.Core)
  - New `PayrunPreviewRetroException`, replaced SHA1 with SHA256, regex timeout for ReDoS prevention, stream and DataTable fixes
  - `IDocumentService` with `GenerateAsync`, `MergeAsync` and `ExcelMergeAsync`
  - `Apply` property added to `Query`; `ApplyOperation` added to `QuerySpecification`
  - New `ReportIsolation` enum (`None`, `Global`, `Company`, `Division`, `Employee`)

- [Client.Core](https://github.com/Payroll-Engine/PayrollEngine.Client.Core)
  - `AdminService` — new service (`IAdminService`) with `GetBackendInformationAsync()` calling `GET /api/admin/information`
  - `BackendInformation` model hierarchy: `BackendAuthInformation`, `BackendDatabaseInformation` (incl. `Edition`), `BackendRuntimeInformation`, `BackendAuditTrailInformation`, `BackendCorsInformation`, `BackendRateLimitingInformation`
  - `ApiEndpoints.AdminInformationUrl()` — new endpoint constant
  - `IAttributeService` added to `IDivisionService`, `ITaskService`, `IRegulationService`, `IReportService` — consistent attribute URL endpoints and service implementations across all object types
  - `ReportIsolation` added to `IReport` interface and `Report` model — synchronized with API model

- [Document](https://github.com/Payroll-Engine/PayrollEngine.Document)
  - `IDocumentService.GenerateAsync` — generates a schema document (`.frx` skeleton) from a DataSet or rebuilds the Dictionary section of an existing template (CI mode), preserving all design elements

- [Client.Test](https://github.com/Payroll-Engine/PayrollEngine.Client.Test)
  - New `PayrunEmployeePreviewTestRunner` for preview-based payrun testing without persisting results
  - `PayrunTestRunner` refactored: `ImportAsync` and `TestAsync` are now separate phases, enabling independent re-test without re-import

- [Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole)
  - `ReportBuild` — executes a report and generates a schema document for template design; format-agnostic, output extension derived from `TemplateFile`
    - without `TemplateFile`: generates new skeleton from DataSet
    - with `TemplateFile` (CI mode): updates schema section, preserving layout
  - `PayrunLoadTest`: optional Excel report alongside CSV
    - `/ExcelReport` — write `.xlsx` with derived filename
    - `/ExcelFile=<path>` — explicit Excel output path
    - `/ParallelSetting=<v>` — documents backend `MaxParallelEmployees` in the Excel setup sheet
    - Excel contains three sheets: Setup (machine, OS, ProcessorCount, MaxParallelEmployees), Results (formatted CSV), Avg ms/Employee (pivot with outlier highlighting)
  - `PayrunLoadTest`: optional Markdown report alongside CSV
    - `/MarkdownReport` — write `.md` with derived filename
    - `/MarkdownFile=<path>` — explicit Markdown output path
    - Report sections: **Test Summary** (median timing, per-run breakdown table, ms/Employee and Employees/h columns) and **Test Infrastructure**
      - *Computer:* machine name, OS, framework, CPU model (Windows Registry), CPU cores, RAM total + available (Windows: `GlobalMemoryStatusEx`), disk total + free
      - *Console:* version, build date
      - *Backend:* version, build date, API version, auth mode, max parallel employees, timeouts, script safety analysis, database (type/name/version/edition), audit trail flags, CORS origins, rate limiting policies — sourced from `GET /api/admin/information`

- [Tests](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Tests)
  - `ConsolidatedEdge.Test` *(new)* — `NoRetro` flag isolation in `GetConsolidatedWageTypeResults`: `NoRetro=false` returns the retro-corrected prior value; `NoRetro=true` returns the original main-run value
  - `PayrunTag.Test` *(new)* — `GetWageTypeResults` tag-filter isolation: Alpha-tagged retro sub-run result queryable by tag; non-existent tag returns zero
  - `MultiDivision.Test` *(new)* — division-scoped case value isolation (`valueScope: Division`): same employee across two divisions, each payroll resolves its own salary independently

- [Examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples)
  - `TemporalPayroll` — new example demonstrating the two independent time axes of case value resolution
    - `periodStart` (valueDate): which value was **active** on a given date
    - `evaluationDate`: which entries were **known** on a given date
    - 7 payrun jobs cover a 2×2 retro matrix (past/today × past/today) and 3 forecast scenarios including a forecast entry with validity window expiry
    - minimal regulation (one case field, one wage type, one No-Code action) — all complexity lives in the payrun invocations
  - `ReportPayroll` — new `Payslip` report: single-employee payslip with current-month value, retro column, and YTD accumulation
    - parameters: `PayslipYear`, `PayslipMonth` (zero-padded, e.g. `03`), `EmployeeIdentifier` (optional employee filter)
    - `ReportEndFunction` accumulates months 1..N via `GetConsolidatedWageTypeResults`; builds `Value`, `YtdValue`, `RetroValue` columns
    - columns: `Name` (`WageTypeName - WageTypeNumber`) · `Amount` · `Retro` · `YTD`
    - A4 portrait template with full-width employee card header; negative values in red, retro adjustments highlighted
  - `ReportPayroll` — `CumulativeJournal` default year updated from 2023 to 2025
