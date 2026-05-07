# Payroll Engine — Release Notes

## v1.0.1 - May 2026

### Backend

**Bug Fixes**

* **Report consolidation path** — `ExecuteConsolidatedQuery` in report end scripts silently returned an empty `DataTable` because `RegulationShareRepository` and `TenantIsolationLevel` were never forwarded through the report execution path (`ApiServiceFactory.NewReportSetService` → `ReportProcessor.GetRuntimeSettings`); both values were already correctly wired in the payrun path (fixes [Backend#10](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/10), [Backend#11](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/11))
* **Docker image** — `Create-Model.sql` and `Update-Model.sql` are now copied to `/sql/` in the Dockerfile final stage, fixing the `sql-copy` service failure on `docker compose up` (fixes [#11](https://github.com/Payroll-Engine/PayrollEngine/issues/11))

### Docker

* **docker-compose.ghcr.yml** — robust database existence check (`-W` flag + `tr -d '[:space:]'`), correct `COLLATE SQL_Latin1_General_CP1_CS_AS` on `CREATE DATABASE`
* **docker-compose.yml** — `NUGET_SOURCE: nuget.org` build arg for Backend and WebApp (enables build-from-source without GitHub token), corrected SQL file path (`Create-Model.sql`)

No breaking change — REST API surface is unchanged from v1.0.0.

---

## Docker Images (Linux)

| App | Version | Pull Command |
|-----|---------|-------------|
| PayrollEngine.Backend | 1.0.1 | `docker pull ghcr.io/payroll-engine/payrollengine.backend:1.0.1` |
| PayrollEngine.PayrollConsole | 1.0.0 | `docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:1.0.0` |
| PayrollEngine.WebApp | 1.0.0 | `docker pull ghcr.io/payroll-engine/payrollengine.webapp:1.0.0` |
| PayrollEngine.Mcp.Server | 1.0.0 | `docker pull ghcr.io/payroll-engine/payrollengine.mcp.server:1.0.0` |