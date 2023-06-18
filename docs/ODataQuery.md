# Payroll Engine OData Query

## Basic rules
- field/column name is not case sensitive
- enum values resolved by case insesitive name

## Supported OData query features
- top
- skip
- select (only on db level)
- orderby
- filter
  - Or
  - And
  - Equal
  - NotEqual
  - GreaterThan
  - GreaterThanOrEqual
  - LessThan
  - LessThanOrEqual
  - grouping with ()
  - supported functions
    - startswith (string)
    - endswith (string)
    - contains (string)
    - year (datetime)
    - month (datetime)
    - day (datetime)
    - hour (datetime)
    - minute (datetime)
    - date (datetime)
    - time (datetime)


## Unsupported OData query features
- expand
- search
- filter
    - Add
    - Subtract
    - Multiply
    - Divide
    - Modulo
    - Has
  - all other functions
- lambda operators


## Further information
- OData v4 - https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html
- OData Getting Started Tutorial -  https://www.odata.org/getting-started/basic-tutorial
- DynamicODataToSQL - https://github.com/DynamicODataToSQL/DynamicODataToSQL
