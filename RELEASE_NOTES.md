# Payroll Engine — Release Notes

## v1.0.0 - Apr 2026

### Highlights

* **Wage type caches** — **`WageTypeCycleCache`** and **`WageTypeConsolidatedCycleCache`** bulk-load cycle and consolidated wage-type results once per employee when wage types are tagged via the corresponding payroll cluster sets, reducing database round-trips during payrun scripts
* **`PasswordAvailable`** — user API and client models expose whether a password is set without transferring the hash
* **Exchange import** — payrun jobs that end with `Abort`/`Cancel` and `CompletedJobStatus=Abort` are treated as an expected test outcome during import, not as a hard import failure

### Backend

**Database Update required** — run the **Update-Model** scripts (SQL Server and MySQL) from schema **0.9.7 → 1.0.0** before starting the backend. The nine `Payroll` columns `ClusterSetCase`, `ClusterSetCaseField`, `ClusterSetCollector`, `ClusterSetCollectorRetro`, `ClusterSetWageType`, `ClusterSetWageTypeRetro`, `ClusterSetCaseValue`, `ClusterSetWageTypePeriod`, and `ClusterSetWageTypeLookup` are replaced by a single **`ClusterSet`** JSON column; existing data is migrated in the scripts. The persistence layer enforces **minimum schema version 1.0.0** — the backend will not start against a pre-1.0.0 database.

**New Features**

* **`WageTypeCycleCache`** — for wage types tagged via `Payroll.ClusterSet.ClusterSetWageTypeCycle`, `GetWageTypeResults` data for the cycle/YTD path is loaded in bulk once per employee at payrun employee start; the cache is reset and reloaded before retro re-evaluation
* **`WageTypeConsolidatedCycleCache`** — for wage types tagged for the consolidated cache, `GetConsolidatedWageTypeResults` is bulk-loaded once per employee; calls with `noRetro=true` bypass the cache by design
* **`PasswordAvailable`** in the user API response — derived from the stored hash in memory; the password hash remains `[JsonIgnore]` on the model

**Bug Fixes**

* **ClusterSet persistence** — pre-serialize `ClusterSet` as PascalCase JSON before write to avoid `sql_variant` conversion issues; register `JsonObjectTypeHandler<PayrollClusterSets>` for correct Dapper deserialization on read
* **Payrun jobs** — `CompletedJobStatus=Abort` is no longer applied to successfully completed jobs; abort remains reserved for processor failures and expected-abort test scenarios
* **`PayrunProcessorSettings`** — XML documentation for `MaxParallelPersist` default corrected (validated by load tests)

**Breaking Change**

* **Database schema 1.0.0** — `Payroll` cluster-set columns consolidated into one **`ClusterSet`** JSON column; **breaking change** (see Database Update above)

### Libraries

* **Client.Core** — `IPayroll` / `Payroll`: individual `ClusterSet*` string properties replaced by a single **`ClusterSet`** property of type `PayrollClusterSets` **breaking change**; **`PasswordAvailable`** on `IUser` / `User`; **ExchangeImport** honors intentional abort status for test expectations; project references use **`$(Version)`** for PE dependencies; release workflow no longer patches versions with `sed`
* **Client.Scripting** — fixed **double-encoding** of strings in `PayrunFunction`; GitHub Actions `pages.yml` patches PE dependency versions before build

**Breaking Change**

* **JSON schema (`PayrollEngine.Exchange.schema.json`)** — the former top-level `Payroll` properties `clusterSetCase`, `clusterSetCaseField`, `clusterSetCollector`, `clusterSetCollectorRetro`, `clusterSetWageType`, `clusterSetWageTypeRetro`, `clusterSetCaseValue`, and `clusterSetWageTypePeriod` are removed; the same references must appear under **`clusterSet`** (`PayrollClusterSets`). Existing payroll JSON files used for import/export must be migrated — **breaking change**
