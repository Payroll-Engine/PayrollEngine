# Test-DbProviders

Runs the PayrollEngine integration tests against all supported database providers and writes a
result report. Each scenario sets up its own database, starts the backend with the matching
provider and runs every test as a separate PayrollConsole process.

## Scenarios

| Scenario | Provider | Database setup | Environment |
|:--|:--|:--|:--|
| `SqlServerFull` | SQL Server | `Create-Model.sql` on an empty test database | local SQL Server |
| `SqlServerUpdate` | SQL Server | baseline schema + baseline data → `Update-Model.sql` | local SQL Server |
| `MySqlFull` | MySQL | `Create-Model.mysql.sql` | Docker container |
| `MySqlUpdate` | MySQL | baseline schema + baseline data → `Update-Model.mysql.sql` | Docker container |
| `PostgresFull` | PostgreSQL | `Create-Model.pg.sql` with functions and procedures | Docker container |
| `PostgresUpdate` | PostgreSQL | baseline schema + baseline data → `Update-Model.pg.sql` | Docker container |

### Update Scenarios

The update scenarios verify the migration against existing data:

1. The backend release tag (default `v1.1.0`) is extracted with `git archive` and built once
   into the working folder (`baseline-v1.1.0`).
2. The baseline schema is created from the scripts of the release tag.
3. The baseline backend is started and the examples (`Examples\Setup.All.pecmd`,
   `Examples\Test.All.pecmd`) produce tenants, payrun jobs and results.
4. The current `Update-Model` script migrates the database.
5. The pay date backfill is verified:
   - `PayrunJob.PayDate` equals the date of `PeriodEnd`
   - `PayDate` of wage type, collector and payrun results equals the payrun job `PayDate`
6. The tests run on the current backend.

## Tests

Per scenario the script runs every entry of:

- `Tests\Test.All.pecmd`
- `Examples\Setup.All.pecmd` (setup data required by some example tests)
- `Examples\Test.All.pecmd`

Commented entries (`#`) are reported as `skip`. Each entry is executed as a separate
`pecmd` process, a failing test does not stop the run.

## Isolation

The script does not touch existing databases or containers:

| Resource | Value |
|:--|:--|
| SQL Server database | `PayrollEngine_DbTest` (dropped and recreated per scenario, `PayrollEngine` is rejected) |
| MySQL containers | `pe-dbtest-mysql-full` (port 3316), `pe-dbtest-mysql-upd` (port 3317) |
| PostgreSQL containers | `pe-dbtest-pg-full` (port 5442), `pe-dbtest-pg-upd` (port 5443) |
| Backend | `http://localhost:5199` |

Containers are removed after each scenario unless `-KeepContainers` is set.

## Prerequisites

- .NET SDK
- `sqlcmd` and a local SQL Server with Windows authentication (SQL Server scenarios)
- Docker Desktop running (MySQL and PostgreSQL scenarios)
- Git tag of the baseline release in the backend repository (update scenarios)

## Parameters

| Parameter | Default | Description |
|:--|:--|:--|
| `-Scenario` | all six | Scenarios to run |
| `-Test` | `*` | Wildcard filter on the test folder names |
| `-BaselineVersion` | `1.1.0` | Previous release for the update scenarios |
| `-ReposRoot` | three levels above the script | Repositories root |
| `-WorkDir` | `%TEMP%\pe-dbtest` | Baseline build, logs and reports |
| `-SqlServer` | `localhost` | SQL Server instance |
| `-SqlServerDatabase` | `PayrollEngine_DbTest` | SQL Server test database |
| `-BackendPort` | `5199` | Backend HTTP port |
| `-TenantIsolationLevel` | `Write` | Backend tenant isolation level; the PayrollConsole sends no `Auth-Tenant` header, imports and regulation share tests require `Write` |
| `-TestTimeoutMinutes` | `15` | Timeout per test |
| `-SkipBuild` | off | Skip the Release build of the current backend and PayrollConsole |
| `-KeepContainers` | off | Keep the containers for inspection |

## Usage

```powershell
# all scenarios
.\Test-DbProviders.ps1

# dry run of one scenario with a subset of tests
.\Test-DbProviders.ps1 -Scenario PostgresUpdate -Test 'Payrun*'

# Docker scenarios only, keep containers for inspection
.\Test-DbProviders.ps1 -Scenario MySqlFull, MySqlUpdate, PostgresFull, PostgresUpdate -KeepContainers
```

## Output

Each run creates a folder `run-<timestamp>` in the working folder:

| File | Content |
|:--|:--|
| `Report.md` | Scenario summary, test matrix and backfill details |
| `<Scenario>\backend*.log` | Backend output (baseline and current) |
| `<Scenario>\database.log` | Database setup and migration output |
| `<Scenario>\<Set>-<Test>-<setup/test>.log` | PayrollConsole output per entry |

The script exits with code `1` if any scenario fails.

## Release Maintenance

After each release, use the new previous release as baseline (`-BaselineVersion`) and update
the default value in the script.
