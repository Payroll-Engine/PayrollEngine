# FastReport Template Development

PayrollEngine uses [FastReport Open Source](https://github.com/FastReports/FastReport)
as the report client for `.frx` templates. The template must match the DataSet schema
produced by the report's queries and scripts — field names, table names, and relations
must agree exactly. The `ReportBuild` PayrollConsole command automates this by
executing the report against the live backend and generating or updating the `.frx`
schema document.

For visual template design, download the free
[FastReport Community Edition Designer](https://github.com/FastReports/FastReport/releases/latest)
(`FastReport.Community.{Version}.zip` → unpack → `Designer.exe`).

> **Note:** `Report.Build.pecmd` is a convenience wrapper that calls the
> `ReportBuild` PayrollConsole command. It has no relation to payrun build steps.

---

## Step 1 — Create the initial template skeleton

Run `ReportBuild` **without** `TemplateFile` to execute the report and generate a
new `.frx` skeleton populated with the correct DataSet schema (tables, columns,
relations in the Dictionary section):

```
ReportBuild tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:CumulativeJournal culture:de-CH targetFile:new.frx
```

or use the provided command file:

```
CumulativeJournal/Report.Build.pecmd
```

The generated `new.frx` contains a valid FastReport Dictionary with all DataSet
tables pre-wired. Open it in the FastReport Designer to build the visual layout,
then save it as `Report.frx` in the report subdirectory.

---

## Step 2 — Update the schema after data model changes (CI mode)

When the regulation changes — new wage types are added, queries are extended, or
script functions add new columns or tables — the `.frx` Dictionary section goes
out of sync with the actual DataSet. Run `ReportBuild` **with** `TemplateFile` to
update only the Dictionary section while preserving all design elements (bands,
textboxes, formatting, layout):

```
ReportBuild tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:CumulativeJournal culture:de-CH templateFile:Report.frx targetFile:Report.frx
```

This is the recommended pattern for CI pipelines: after every regulation change
that affects the report data model, re-run `ReportBuild templateFile:Report.frx`
to keep the template in sync without manual Designer intervention.

---

## ReportBuild command reference

```
ReportBuild <Tenant> <User> <Regulation> <Report> [options]
```

| Argument / Option | Description |
|:--|:--|
| `Tenant` | Tenant identifier (positional 1) |
| `User` | User identifier (positional 2) |
| `Regulation` | Regulation name (positional 3) |
| `Report` | Report name (positional 4) |
| `templateFile:<path>` | Existing `.frx` — CI mode: updates Dictionary, preserves layout |
| `parameterFile:<path>` | JSON parameter file (default: `parameters.json` in working dir) |
| `culture:<culture>` | Report culture, e.g. `de-CH` |
| `targetFile:<path>` | Output file name (default: `<Report>_<timestamp>[.frx]`) |
| `/shellopen` | Open the generated file after build |

**Behaviour without `TemplateFile`:** generates a new `.frx` skeleton from the
DataSet schema. Use this to start designing a new template.

**Behaviour with `TemplateFile` (CI mode):** reads the existing `.frx`, replaces
only the `<Dictionary>` XML section with a fresh schema derived from the current
DataSet, and writes the result to `TargetFile`. All bands, objects, expressions,
and formatting are preserved.

---

## Reports with `Report.Build.pecmd`

The following reports include a `Report.Build.pecmd` that invokes `ReportBuild`
without `TemplateFile`, generating a fresh `new.frx` skeleton:

| Report | Command file | Purpose |
|:--|:--|:--|
| `CumulativeJournal` | `CumulativeJournal/Report.Build.pecmd` | Generate schema skeleton for the 12-month pivot layout |
| `Payslip` | `Payslip/Report.Build.pecmd` | Generate schema skeleton for the current/retro/YTD layout |

Reports without a `Report.Build.pecmd` use only static queries declared in
`Report.json` — their DataSet schema is fully deterministic and does not require
script execution to be known at design time.
