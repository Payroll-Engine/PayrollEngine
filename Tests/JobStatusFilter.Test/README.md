# JobStatusFilter.Test

Regression test for the **job status filter of the result queries**
([Backend #15](https://github.com/Payroll-Engine/PayrollEngine.Backend/issues/15)).

A result query with a `jobStatus` filter must return only results of jobs with
exactly this status. The defective filter `JobStatus & @jobStatus = JobStatus`
evaluates a bitwise subset on the sequential `PayrunJobStatus` values:

| Requested status | Correct match | Defective match |
|:-----------------|:--------------|:----------------|
| `Complete` (3) | Complete | Draft, Release, Process, Complete |
| `Forecast` (4) | Forecast | Draft, Forecast |
| `Release` (1) | Release | Draft, Release |
| `Process` (2) | Process | Draft, Process |

Because the consolidated queries return the newest result per period, a newer
open correction job (Draft/Release/Process) replaces the last completed result.

---

## Scenario

**Tenant:** `JobStatusFilter.Test` | **Division:** `JobStatusFilterDivision` (de-CH)  
**Employee:** `lena.vogel@jobstatusfilter.test`

Five jobs for January 2024, one per job status, each with a distinct salary.
The evaluation date orders the jobs; the result creation date follows the evaluation date.

| Job | Status | Forecast | Evaluation date | WT101 Salary |
|:----|:-------|:---------|:----------------|-------------:|
| `Jan24.Complete` | Complete | — | 2024-01-10 | 1 000 |
| `Jan24.Forecast` | Forecast | `StatusCheck` | 2024-01-12 | 4 000 |
| `Jan24.Release` | Release | — | 2024-01-20 | 9 100 |
| `Jan24.Process` | Process | — | 2024-01-25 | 9 200 |
| `Jan24.Draft` | Draft | — | 2024-01-28 | 9 000 |
| `Feb24.StatusCheck` | Forecast | `StatusCheck` | 2024-02-25 | 2 000 |

The Draft job is the last legal job: an open Draft job rejects further legal jobs
of the payroll. The status check job is therefore a forecast job (`retroPayMode = None`),
which queries the January results from the database.

No cluster sets are configured, so no result cache intercepts the queries and
every query reaches the stored procedure.

---

## Assertions — `Feb24.StatusCheck`

| WT | Query | Status | Expected | Defective |
|---:|:------|:-------|---------:|----------:|
| 201 | `GetConsolidatedWageTypeResults` | Complete | **1 000** | 9 000 |
| 202 | `GetConsolidatedWageTypeResults` | Release | **9 100** | 9 000 |
| 203 | `GetConsolidatedWageTypeResults` | Process | **9 200** | 9 000 |
| 204 | `GetConsolidatedWageTypeResults` | Draft | 9 000 | 9 000 |
| 205 | `GetConsolidatedWageTypeResults` | Forecast (`StatusCheck`) | **4 000** | 9 000 |
| 206 | `GetConsolidatedWageTypeResults` | none | 9 000 | 9 000 |
| 211 | `GetWageTypeResults` (previous period) | Complete | **1 000** | 28 300 |
| 212 | `GetWageTypeResults` (previous period) | Forecast (`StatusCheck`) | **4 000** | 13 000 |
| 213 | `GetWageTypeResults` (previous period) | none | 28 300 | 28 300 |
| 221 | `GetConsolidatedCollectorResults` | Complete | **1 000** | 9 000 |
| 222 | `GetCollectorResults` (previous period) | Complete | **1 000** | 28 300 |
| 231 | `GetConsolidatedWageTypeCustomResults` | Complete | **1 000** | 9 000 |
| 232 | `GetWageTypeCustomResults` (previous period) | Complete | **1 000** | 28 300 |
| 241 | `GetConsolidatedCollectorCustomResults` | Complete | **1 000** | 9 000 |

WT204, WT206 and WT213 are controls: an exact Draft match and the unfiltered query
must keep their behaviour (the unfiltered consolidated query returns the newest job).

The non-consolidated queries return all matching results of the period, so the
defective filter sums the leaked jobs (1 000 + 9 100 + 9 200 + 9 000 = 28 300).

## Stored Procedure Coverage

| Stored procedure | Covered by |
|:-----------------|:-----------|
| `GetConsolidatedWageTypeResults` | WT201–206 |
| `GetConsolidatedWageTypeCustomResults` | WT231 |
| `GetConsolidatedCollectorResults` | WT221 |
| `GetConsolidatedCollectorCustomResults` | WT241 |
| `GetWageTypeResults` | WT211–213 |
| `GetWageTypeCustomResults` | WT232 |
| `GetCollectorResults` | WT222 |
| `GetCollectorCustomResults` | — (no scripting query) |
| `GetConsolidatedPayrunResults` | — (no scripting query) |

---

## Running the Test

```cmd
cd Tests\JobStatusFilter.Test
pecmd Test.pecmd
```

## See Also

- [ConsolidatedEdge.Test](../ConsolidatedEdge.Test/) — `NoRetro` flag on consolidated results
- [ForecastPayroll.Test](../ForecastPayroll.Test/) — forecast payrun jobs
