# TaxTablePayroll Example

This integration example shows how large national tax tables can be used
as the basis for payroll calculations. Three concepts work together:

1. **Large lookup import** — bulk-loading thousands of records from a
   flat text file into a regulation lookup
2. **Sliced import** — splitting an oversized import into chunks, with
   automatic `UpdateMode` sequencing to reset or append each slice
3. **Range lookup with named columns** — resolving the withholding tax
   deduction per employee from a composite key and income bracket at
   payrun time

The regulation defines the lookup schema; the import fills it with data;
the wage type expression reads from it at runtime. Each concept maps to
one step in this pipeline.

This example is intentionally country-neutral. The map and regulation
work with any fixed-width tax table file that follows the record layout
described in this file.

---

## Concept 1 — Large Lookup Import

National tax authorities typically publish annual tax tables as flat text
files with several thousand records per year. Maintaining this volume of
data manually is not practical.

The `LookupTextImport` command reads the file directly and writes all
lookup values to the regulation via the backend API:

```
LookupTextImport TaxTableTenant TaxTable.Payroll taxrate-monthly.txt TaxTable.Monthly.map.json /bulk
```

The map file `TaxTable.Monthly.map.json` defines how each fixed-width
line is converted into a lookup value — which positions hold the key,
the range value, and each named column.

The lookup `TaxTable.Monthly` is declared in the regulation with no
initial values. The import fills it. This separation keeps the regulation
stable across annual updates: only the data file and the import step change.

---

## Concept 2 — Sliced Import

For tables that exceed practical API request sizes, `LookupTextImport`
supports a `SliceSize` parameter that splits the import into multiple
chunks.

The `UpdateMode` on the lookup controls how each chunk is written:

| Slice | UpdateMode | Effect |
|:--|:--|:--|
| First | `Update` | Resets existing lookup values, then inserts |
| Subsequent | `NoUpdate` | Appends to the existing lookup |

`LookupTextImport` manages this automatically — the first slice uses
`Update`, every following slice uses `NoUpdate`. The client specifies
only the slice size; the sequencing and mode assignment are handled
internally:

```
LookupTextImport TaxTableTenant TaxTable.Payroll taxrate-monthly.txt TaxTable.Monthly.map.json . 500 /bulk
```

The `.` placeholder for `TargetFolder` (argument 5) is required because
`SliceSize` occupies argument 6 and cannot be omitted.

---

## Concept 3 — Range Lookup with Named Columns

### Record Structure

`TaxTable.Monthly` uses no `RangeMode` — the tax authority publishes
pre-calculated deduction amounts per bracket, so no rate application is
needed at runtime. For threshold and progressive rate lookups see
[Lookups](Lookups).

Each lookup record stores one income bracket (range value) and six
deduction columns, one per taxpayer category. The composite key combines
the period type and the tax table number assigned to the employee's
municipality:

```
Key       Range value   Col1    Col2    Col3    Col4    Col5    Col6
"30 34"   40000         10300   7800    9100    8400    8900    7200
"30 34"   50000         13100   9900    11500   10700   11300   9200
```

### Wage Type Expression

At payrun time, the wage type expression resolves the deduction with
`GetRangeObjectLookup`. It finds the bracket covering the employee's
salary, then reads the column for the employee's taxpayer category:

```csharp
var tableNumber = GetCaseValue<string>("TaxTableNumber");
var column      = GetCaseValue<int>("TaxColumn");
var salary      = WageType[100];
var key         = "30 " + tableNumber;
var colName     = "Col" + column;
var deduction   = GetRangeObjectLookup<decimal>("TaxTable.Monthly", salary, colName, key);
return -deduction;
```

The employee case `TaxTableSettings` holds `TaxTableNumber` and
`TaxColumn`. These are set once per employee and used on every payrun.

---

## Data Source

Download the monthly tax table text file from your national tax authority
and place it in the `TaxTablePayroll/` folder as `taxrate-monthly.txt`.

**Reference implementation (Sweden):**
https://skatteverket.se/foretag/arbetsgivare/arbetsgivaravgifterochskatteavdrag/skattetabeller/tekniskbeskrivningforskattetabeller.4.319dc1451507f2f99e86ee.html

File: *Månadslön txt* (~389 kB, ~7,100 records)  
Format specification: *Postbeskrivning för allmänna tabeller* (doc, same page)

## Record Format

```
Pos  Len  Field
─────────────────────────────────────────────────────────────────
  1    2   Period type: "14" (bi-weekly) or "30" (monthly)
  3    1   Value type:  "B" (amount) or "%" (percentage)
  4    2   Table number (e.g. 29–42)
  6    7   Income range: lower bound
 13    7   Income range: upper bound
 20    5   Column 1 — employee < 66 yrs, wage income
 25    5   Column 2 — person ≥ 66 yrs, pension income
 30    5   Column 3 — employee ≥ 66 yrs, wage income
 35    5   Column 4 — sickness/activity compensation < 66 yrs
 40    5   Column 5 — other pensionable income
 45    5   Column 6 — pension income < 66 yrs
```

Records with value type `%` apply to incomes above the upper amount
threshold and carry a percentage rate instead of a fixed deduction.

## File Structure

```
TaxTablePayroll/
├── README.md
├── Setup.pecmd                     ← Full setup: payroll + import
├── Import.pecmd                    ← Standalone lookup import (step 2)
├── Delete.pecmd                    ← Cleanup
├── Test.pecmd                      ← Payrun employee tests
├── TaxTable.Payroll.yaml           ← Regulation, cases, wage types, collectors, payrun
├── TaxTable.Monthly.map.json       ← LookupTextImport map
├── TaxTable.Test.et.yaml           ← Payrun test definitions
└── taxrate-monthly.txt             ← Place downloaded file here (not in repo)
```

## Setup

```
1. Download taxrate-monthly.txt and place in TaxTablePayroll/
2. Run TaxTablePayroll/Setup.pecmd
```

## Steps (Setup.pecmd)

```
0 TenantDelete /trydelete       → clean previous run
1 TaxTable.Payroll.yaml         → regulation, tenant, employees, payroll, payrun
2 LookupTextImport              → bulk-fill TaxTable.Monthly (~7,100 records)
```
