# Regulation Report

Detail view of a single regulation, filtered by parameter. Shows the regulation
name and description as a card, followed by its Collectors and Wage Types as
distinct sections with gold-underline headers.

---

## Report Overview

| Property | Value |
|:--|:--|
| Report name | `Regulation` |
| Category | `Regulations` |
| Clusters | `Payroll` · `WageType` · `Collector` |
| Script phases | None (static queries only) |
| Parameters | `TenantId` (hidden) · `RegulationId` (mandatory) · `Regulations.Filter` (hidden) |
| Templates | `DefaultGerman` (de) · `DefaultEnglish` (en) |
| Output | Excel (`Report.Excel.pecmd`) · PDF (`Report.Pdf.pecmd`) |

---

## Report Template (FRX)

Portrait A4, Clean Lines design. Card-style layout for the regulation header,
followed by two collapsible sub-sections.

**Regulation card:**
| Element | Top | Height | Style |
|:--|--:|--:|:--|
| Teal accent stripe | 0 | 4 | `Fill.Color="45, 130, 140"` |
| Card background | 4 | 44 | Light blue-gray, bordered |
| Regulation name | 12 | 28 | `11pt Bold, navy` |
| Description | 52 | 22+ | `9pt`, dark, `CanGrow` |

**Column layout — Collectors (single column):**
| Column | Left | Width |
|:--|--:|--:|
| Name | 0 | 718.4 |

**Column layout — Wage Types:**
| Column | Left | Width |
|:--|--:|--:|
| Wage Type | 0 | 628.4 |
| No. | 628.4 | 90 |

**Bands:**
- `ReportTitleBand` — dark navy, logo left, "Regulation" right
- `PageHeaderBand` — `Height=37.8`, breathing space only
- `DataBand` (Regulations) — card + description, `CanGrow`
  - `DataBand` (Collectors) via `RegulationCollectors`
    - `DataHeaderBand` — "Collectors" gold underline
    - Data rows: collector name, horizontal separator
  - `DataBand` (WageTypes) via `RegulationWageTypes`
    - `DataHeaderBand` — "No." + "Wage Type" gold underline
    - Data rows: number (muted blue) + name, horizontal separator
- `PageFooterBand` — dark navy, date left, page number right

---

## Parameters

| Name | Type | Visible | Description |
|:--|:--|:--|:--|
| `TenantId` | Integer | Hidden | Injected by runtime |
| `RegulationId` | String | Yes | Selected regulation (mandatory) |
| `Regulations.Filter` | String | Hidden | OData filter `Id eq '$RegulationId$'` |

---

## Data Model

```
Regulations (QueryRegulations, filtered by RegulationId)
    ├── Collectors  (QueryCollectors)
    │       RegulationId → Regulations.Id   [RegulationCollectors]
    └── WageTypes   (QueryWageTypes)
            RegulationId → Regulations.Id   [RegulationWageTypes]
```

All three queries are declared statically in `Report.json`. No script phases are used.
The `Regulations.Filter` parameter limits the result to the single selected regulation.

---

## Files

| File | Description |
|:--|:--|
| `Report.json` | Report definition — parameters, queries, relations, templates |
| `Report.frx` | FastReport template (Portrait A4, Clean Lines) |
| `parameters.json` | Default parameters for PayrollConsole execution |
| `Import.pecmd` | Import report definition |
| `Report.Excel.pecmd` | Run report and save as Excel |
| `Report.Pdf.pecmd` | Run report and save as PDF |

---

## Features Demonstrated

- **Static query report** — all three queries declared in `Report.json`; no Build, Start, or End script phases required
- **OData filter via hidden parameter** — `Regulations.Filter` injects `Id eq '$RegulationId$'` automatically; the user selects only the regulation, not the OData string
- **Two static DataRelations** — `RegulationCollectors` and `RegulationWageTypes` declared in `Report.json`; nested DataBands in FastReport render each section independently
- **Card layout with `CanGrow`** — regulation name displayed in a teal-stripe card; description uses `CanGrow` to accommodate variable-length text
- **Gold-underline section headers** — `DataHeaderBand` per child DataBand renders a section title with gold bottom border before the first data row
- **Mandatory parameter** — `RegulationId` marked `mandatory: true`; the report cannot run without a selection
