# EmployeeCaseValues Report

Demonstrates the full three-phase report pipeline (Build / Start / End) with dynamic
parameter population, conditional parameter visibility, and time-based case value queries
with lookup resolution.

---

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `EmployeeCaseValues` |
| Clusters | `Employee` · `CaseValue` |
| Script phases | Build · Start · End |
| Parameters | `TenantId` (hidden) · `PayrollId` · `AllEmployees` · `EmployeeIdentifier` |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) |
| Output | Excel (`Report.Excel.pecmd`) · PDF (`Report.Pdf.pecmd`) |

---

## Script Phases

### Build Phase — `ReportBuildFunction`

Populates the `PayrollId` dropdown from the API and, depending on `AllEmployees`,
shows or hides the `EmployeeIdentifier` parameter.

```csharp
// Populate PayrollId list from API
ExecuteInputListQuery(
    queryMethod: "QueryPayrolls",
    queryParameters: new QueryParameters().Parameter(nameof(TenantId), TenantId),
    reportParameter: "PayrollId",
    identifierFunc: row => row["Id"],
    displayFunc: row => $"{row["Name"]}");

// Show/hide EmployeeIdentifier based on AllEmployees flag
SetParameterHidden("EmployeeIdentifier", allEmployees);
```

### Start Phase — `ReportStartFunction`

Lightweight: injects an OData filter into `Employees.Filter` when a single employee
is selected.

```csharp
if (HasParameter("EmployeeIdentifier"))
{
    SetParameter("Employees.Filter",
        new EqualIdentifier(GetParameter("EmployeeIdentifier")).Expression);
}
```

### End Phase — `ReportEndFunction`

Heavy lifting: resolves the payroll, queries employees (fallback if no start query
ran), calls `ExecuteEmployeeTimeCaseValueQuery` with mixed simple and lookup columns,
then adds the relation manually.

```csharp
// Employees: use existing table or query fresh
var employees = Tables["Employees"]
    ?? ExecuteQuery("QueryEmployees", new QueryParameters().Parameter(nameof(TenantId), TenantId));

// Time-based case values with lookup column
var caseValuesTable = ExecuteEmployeeTimeCaseValueQuery(
    tableName: "CaseValues",
    payrollId: payrollId.Value,
    employeeIds: employeeIds,
    columns:
    [
        new("MonthlyWage"),
        new("EmploymentLevel"),
        new("BirthDate"),
        new("Location", "Location")   // lookup: case field name, lookup name
    ],
    culture: UserCulture);

AddTable(caseValuesTable);
AddRelation("EmployeeCaseValues", employees.TableName, caseValuesTable.TableName, "EmployeeId");
```

---

## Report Template (FRX)

Portrait A4, Clean Lines design. Column layout:

| Column | Left | Width |
|:--|--:|--:|
| Identifier | 0 | 200 |
| Monthly wage | 200 | 130 |
| Employment level | 330 | 130 |
| Birth date | 460 | 130 |
| Location | 590 | 128.4 |

Bands:
- `ReportTitleBand` — dark navy (`#0D2240`), logo left, title right
- `PageHeaderBand` — 75.6 high: upper 37.8 breathing space, column headers at `Top=37.8`
- `DataBand` (`Employees`) → nested `DataBand` (`CaseValues`) via `EmployeeCaseValueRelation`
- `PageFooterBand` — dark navy, date left, page number right

---

## Parameters

| Name | Type | Visible | Description |
|:--|:--|:--|:--|
| `TenantId` | Integer | Hidden | Injected by runtime |
| `PayrollId` | String | Yes | Dropdown populated in Build phase via `QueryPayrolls` |
| `AllEmployees` | Boolean | Yes | Default `true`; hides `EmployeeIdentifier` when true |
| `EmployeeIdentifier` | String | Conditional | Hidden when `AllEmployees = true`; OData filter set in Start phase |

---

## Data Model

```
Employees (QueryEmployees)
    └── CaseValues (ExecuteEmployeeTimeCaseValueQuery)
            EmployeeId → Employees.Id   [EmployeeCaseValues relation]
```

The `Employees` table is provided by the default query (`QueryEmployees`) defined in
`Report.json`. The `CaseValues` table is constructed in the End script and added via
`AddTable`. The relation is registered with `AddRelation`.

---

## Best Practices

### 1. `ExecuteInputListQuery` for dropdown parameters

Use `ExecuteInputListQuery` in the **Build phase** to populate any parameter that
should appear as a selectable list in the report UI. Provide `identifierFunc` (the
stored value) and `displayFunc` (the human-readable label) separately.

```csharp
ExecuteInputListQuery(
    queryMethod: "QueryPayrolls",
    queryParameters: new QueryParameters().Parameter(nameof(TenantId), TenantId),
    reportParameter: "PayrollId",
    identifierFunc: row => row["Id"],
    displayFunc: row => $"{row["Name"]}");
```

### 2. Conditional parameter visibility

Use `SetParameterHidden` in the **Build phase** to show or hide parameters based on
other parameter values. This avoids showing irrelevant fields to the user.

```csharp
SetParameterHidden("EmployeeIdentifier", allEmployees);
```

### 3. `EqualIdentifier` for OData filter construction

Prefer `EqualIdentifier` (and similar helpers) over raw OData string concatenation in
the **Start phase**. It handles escaping correctly and is refactor-safe.

```csharp
SetParameter("Employees.Filter",
    new EqualIdentifier(GetParameter("EmployeeIdentifier")).Expression);
```

### 4. Table null-check in End phase

The `Employees` table may already exist (populated by the default query) or may be
absent (e.g. when no Start script ran the query). Always guard with a null-check and
fall back to an explicit `ExecuteQuery` call.

```csharp
var employees = Tables["Employees"]
    ?? ExecuteQuery("QueryEmployees", ...);
```

### 5. Lookup columns in `ExecuteEmployeeTimeCaseValueQuery`

Pass two-argument `new("FieldName", "LookupName")` for case fields whose value should
be resolved through a lookup table. The second argument is the lookup name registered
in the regulation.

```csharp
new("Location", "Location")   // resolves the display value via the "Location" lookup
```

### 6. `UserCulture` for culture-aware output

Always pass `culture: UserCulture` to time-based case value queries. This ensures
number formatting, date display, and lookup text match the user's locale.

### 7. Manual relation registration

When tables are constructed dynamically in the End script (not declared in `Report.json`),
register the relation explicitly with `AddRelation` after calling `AddTable`. FastReport
requires the relation to be present in the DataSet before it can render nested DataBands.

```csharp
AddTable(caseValuesTable);
AddRelation("EmployeeCaseValues", employees.TableName, caseValuesTable.TableName, "EmployeeId");
```

---

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — parameters, queries, templates |
| `Scripts.cs` | Build / Start / End script functions |
| `Report.frx` | FastReport template (Portrait A4, Clean Lines) |
| `parameters.json` | Default parameters for PayrollConsole execution |
| `Import.pecmd` | Import report definition |
| `Script.pecmd` | Publish `Scripts.cs` to the regulation |
| `Report.Excel.pecmd` | Run report and save as Excel |
| `Report.Pdf.pecmd` | Run report and save as PDF |

---

## Features Demonstrated

- **Three-phase report pipeline** — Build populates dropdowns and controls parameter visibility; Start injects OData filters; End executes queries and assembles the final DataSet
- **`ExecuteInputListQuery`** — populates the `PayrollId` parameter as a selectable dropdown from an API query in the Build phase
- **Conditional parameter visibility** — `SetParameterHidden` shows or hides `EmployeeIdentifier` based on the `AllEmployees` flag
- **`EqualIdentifier` OData filter** — constructs a type-safe OData filter expression in the Start phase without raw string concatenation
- **Table null-check pattern** — `Tables["Employees"] ?? ExecuteQuery(...)` handles the case where the default query already populated the table
- **Lookup column resolution** — `new("Location", "Location")` in `ExecuteEmployeeTimeCaseValueQuery` resolves a case field value through a regulation lookup
- **`UserCulture` for locale-aware output** — passed to time-based case value queries to match number and date formatting to the user's locale
- **Manual relation registration** — `AddRelation` registers the relation between dynamically constructed tables so FastReport can render nested DataBands
