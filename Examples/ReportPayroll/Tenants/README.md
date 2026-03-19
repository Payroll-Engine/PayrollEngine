# Tenants Report

A simple overview report listing all tenants together with their custom attributes.
This example demonstrates two reporting concepts:

- **Script-free report** — data is delivered entirely by a static query (`QueryTenants`),
  no `ReportStartFunction`, `ReportBuildFunction`, or `ReportEndFunction` is required.
- **Object attribute reporting** — tenant attributes are a client-controlled dictionary
  that varies per tenant. The `attributeMode: "Table"` setting flattens this dictionary
  into a typed `DataTable` so attributes can be displayed as columns in the template.

> **Note:** Attribute columns are specific to this example tenant. Because attributes are
> freely defined by each client, a generic tenant report cannot rely on specific attribute
> keys. This report intentionally targets the `Report.Tenant` example data where the
> attributes `ErpId`, `MaxEmployee`, and `SyncPayService` are known.

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `Tenants` |
| Template | `Report.frx` (FastReport) |
| Cultures | `de`, `en` |
| Cluster | `Tenant` |
| Query | `QueryTenants` |
| Attribute mode | `Table` |

## How attribute rendering works

Attribute rendering is enabled via the `attributeMode` setting in `Report.json`:

```json
{
  "name": "TenantsSimple",
  "attributeMode": "Table",
  ...
}
```

When `attributeMode` is set to `"Table"`, the PayrollEngine report processor
calls `GetAttributeTable()` on every DataTable that has an `Attributes` column.
The method:

1. Parses the JSON attributes dictionary for each row.
2. Creates a sibling table named `<TableName>Attributes` (here: `TenantsAttributes`).
3. Adds one column per distinct attribute key found across all rows.
4. Adds one row per source row that has at least one attribute, with `RelationId`
   pointing back to the parent `Id`.
5. Registers a DataRelation `TenantsAttributesRelation`
   (`Tenants.Id` → `TenantsAttributes.RelationId`).

In the FastReport template the child DataBand (`Data2`) uses
`Relation="TenantsAttributesRelation"` so FastReport automatically filters
attribute rows to the current tenant. `PrintIfDetailEmpty="false"` on the master
DataBand (`Data1`) suppresses tenants that carry no attributes.

## Attribute columns (example data)

| Column | Description |
|:--|:--|
| `ErpId` | ERP system identifier |
| `MaxEmployee` | Maximum number of employees |
| `SyncPayService` | Whether payroll sync is enabled |

## Running the report

```
# import report definition
Exchange Import.pecmd

# generate PDF (opens automatically)
Report tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:Tenants culture:de /pdf /shellopen
```

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — query, attribute mode, template references |
| `Report.frx` | FastReport template — "Clean Lines" layout |
| `Import.pecmd` | Import script for PayrollConsole |

## See Also

- [Best Practices: Reporting](https://payrollengine.org/Concepts/BestPracticesReporting/)
- [Users](../Users/) — same layout, users instead of tenants
- [EmployeesXml](../EmployeesXml/) — another script-free report (XSL output path)

---

## Features Demonstrated

- **Script-free report** — data delivered entirely by a static `QueryTenants` query; no Build, Start, or End script phases required
- **`attributeMode: "Table"`** — flattens the tenant attribute dictionary into a typed `DataTable`; one column per distinct attribute key across all rows
- **Auto-generated DataRelation** — `TenantsAttributesRelation` (`Tenants.Id` → `TenantsAttributes.RelationId`) registered automatically by the attribute processor
- **`PrintIfDetailEmpty="false"`** — master DataBand suppresses tenants that carry no attributes
- **Template attachment extension** — `input.attachmentExtensions: ".frx"` allows the `.frx` file to be attached to the report template
