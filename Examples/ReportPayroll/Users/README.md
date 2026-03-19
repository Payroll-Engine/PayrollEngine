# Users Report

A simple overview report listing all users of a tenant.
This example demonstrates a **script-driven report** — the query and parameter are set
dynamically via `startExpression` and `buildExpression` rather than a static query binding.

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `Users` |
| Template | `Report.frx` (FastReport) |
| Cultures | `de`, `en` |
| Cluster | `User` |
| Query | `QueryUsers` (set via `startExpression`) |

## How the query is configured

Unlike fully static reports, UsersSimple uses expressions to configure the query at runtime:

```json
{
  "name": "UsersSimple",
  "buildExpression": "SetParameter(\"Users.TenantId\", TenantId);",
  "startExpression": "SetQuery(\"Users\", \"QueryUsers\"); return null;"
}
```

`startExpression` registers the `QueryUsers` API query for the `Users` data table.  
`buildExpression` injects the current `TenantId` as a query filter parameter so only
users belonging to the active tenant are returned.

## Columns

| Column | Description |
|:--|:--|
| `Identifier` | Unique user login identifier |
| `FirstName` | User's first name |
| `LastName` | User's last name |

## Running the report

```
# import report definition
Exchange Import.pecmd

# generate PDF (opens automatically)
Report tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:Users culture:de /pdf /shellopen
```

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — query expressions, template references |
| `Report.frx` | FastReport template — "Clean Lines" layout |
| `Import.pecmd` | Import script for PayrollConsole |

## See Also

- [Best Practices: Reporting](https://payrollengine.org/Concepts/BestPracticesReporting/)
- [Tenants](../Tenants/) — same layout, tenants with attributes
- [Regulation](../Regulation/) — multi-section regulation detail report

---

## Features Demonstrated

- **Dynamic query injection** — `startExpression` calls `SetQuery("Users", "QueryUsers")` to assign the API query at runtime; no static query binding in `Report.json` required
- **Build-phase parameter injection** — `buildExpression` calls `SetParameter("Users.TenantId", TenantId)` to filter users to the active tenant before the query runs
- **Inline expressions instead of script files** — `buildExpression` and `startExpression` declared directly in `Report.json`; no separate `.cs` script file needed for simple logic
- **Script-free UI** — no parameters visible to the user; the tenant filter is injected automatically without any parameter form
