### Features

- [Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend)
  - `MaxParallelEmployees` default changed from sequential to auto (`ProcessorCount`) **breaking change** — use `off` or `-1` to restore sequential behavior
    - values: `0`/empty = auto, `off`/`-1` = sequential, `half` = ProcessorCount/2, `max` = ProcessorCount, `1`–`N` = explicit

- [Document](https://github.com/Payroll-Engine/PayrollEngine.Document)
  - `IDocumentService.GenerateAsync` — generates a schema document (`.frx` skeleton) from a DataSet or rebuilds the Dictionary section of an existing template (CI mode), preserving all design elements

- [Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole)
  - `ReportBuild` — executes a report and generates a schema document for template design; format-agnostic, output extension derived from `TemplateFile`
    - without `TemplateFile`: generates new skeleton from DataSet
    - with `TemplateFile` (CI mode): updates schema section, preserving layout
  - `PayrunLoadTest`: optional Excel report alongside CSV
    - `/ExcelReport` — write `.xlsx` with derived filename
    - `/ExcelFile=<path>` — explicit Excel output path
    - `/ParallelSetting=<v>` — documents backend `MaxParallelEmployees` in the Excel setup sheet
    - Excel contains three sheets: Setup (machine, OS, ProcessorCount, MaxParallelEmployees), Results (formatted CSV), Avg ms/Employee (pivot with outlier highlighting)
