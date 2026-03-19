# EmployeesXml Report

Exports all employees as structured XML, transformed via XSLT and validated
against an XSD schema. This is a **script-free, query-only report** that
demonstrates the non-FastReport output path: `contentType: application/xsl`
replaces the usual `.frx` template with an XSL stylesheet.

---

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `EmployeesXml` |
| Script phases | None |
| Template | `Employees.xsl` (XSL transform) |
| Schema | `Employees.xsd` (XSD validation) |
| Cultures | `de`, `en` |
| Clusters | `Employee` · `CaseValue` · `XML` |
| Parameters | `TenantId` (hidden) |
| Output | XML (`Report.Xml.pecmd`) |

---

## How the XSL output path works

The report uses `contentType: application/xsl` in `Report.json` instead of
the default FastReport content type:

```json
{
  "name": "DefaultGerman",
  "culture": "de",
  "contentType": "application/xsl",
  "contentFile": "Employees.xsl",
  "schemaFile": "Employees.xsd"
}
```

When the report is executed:

1. `QueryEmployees` runs and returns an in-memory `Employees` DataTable.
2. The PayrollEngine document processor serialises the DataSet to an intermediate
   XML representation (the DataSet's native XML format).
3. `Employees.xsl` is applied as an XSLT transform, producing the final structured
   XML document.
4. The output is validated against `Employees.xsd` before delivery.

No parameter form is shown to the user — the report runs directly without any
visible input.

---

## XSL Transform (`Employees.xsl`)

The stylesheet maps each row of the `Employees` DataTable to an `<Employee>`
element, selecting the fields: `Id`, `Status`, `Created`, `Updated`, `TenantId`,
`Identifier`, `FirstName`, `LastName`, and further employee properties.

Root element produced: `<Employees>`.

---

## Parameters

| Name | Type | Visible | Description |
|:--|:--|:--|:--|
| `TenantId` | Integer | Hidden | Injected by runtime — no user-facing parameters |

---

## Data Model

```
Employees (QueryEmployees)
```

Single table, no relations. The XSL transform handles all structure.

---

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — query, `contentType: application/xsl`, template and schema references |
| `Employees.xsl` | XSLT stylesheet — transforms the `Employees` DataTable to structured XML |
| `Employees.xsd` | XSD schema — validates the transformed XML output |
| `Import.pecmd` | Import report definition |
| `Report.Xml.pecmd` | Run report and save as XML |

---

## See Also

- [Best Practices: Reporting](https://payrollengine.org/Concepts/BestPracticesReporting/) — scripting patterns
- [Tenants](../Tenants/) — another script-free report (static query, FastReport output)

---

## Features Demonstrated

- **Script-free report** — data delivered entirely by a static `QueryEmployees` query; no Build, Start, or End script phases required
- **`contentType: application/xsl`** — replaces the FastReport `.frx` template with an XSL stylesheet; the document processor applies the transform automatically
- **XSD validation** — `schemaFile: Employees.xsd` causes the output to be validated after the transform; invalid XML is rejected before delivery
- **No parameter form** — report has no visible parameters and runs directly without user input
- **Dual-culture template** — both `de` and `en` templates share the same `Employees.xsl` and `Employees.xsd`; culture differentiation can be added inside the stylesheet if needed
