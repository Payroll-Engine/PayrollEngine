# CaseDefPayroll Example

A comprehensive case definition reference for **CaseDefPayroll**, demonstrating
every case value type, time type, input attribute, slot hierarchy, case relation,
and action pattern available in the engine.

This example has no payrun logic — it exists as a **UI and data model reference**.
Load it to explore and test case input behavior in the web application.

---

## Regulation: CaseDefPayroll

All cases are `Employee` type assigned to one employee (`višnja.müller@foo.com`).

---

## Value Types

### All Value Types
Every engine value type in a single case, each with practical input attributes:

| Field | ValueType | TimeType | Notable attribute |
|:--|:--|:--|:--|
| `String` | String | Moment | optional |
| `ReadOnlyString` | String | Moment | `input.valueReadOnly: true` |
| `MaskedString` | String | Moment | `input.valueMask: "000-000-0000"` |
| `MultiLineString` | String | Moment | `input.lineCount: 5`, `input.maxLength: 22` |
| `ExpressionString` | String | CalendarPeriod | fixed `defaultStart` |
| `Date` | Date | CalendarPeriod | `minValue: today`, `maxValue: +7d` |
| `DateMonth` | Date | Period | `input.datePicker: month` |
| `DateTime` | DateTime | Timeless | `minValue / maxValue` |
| `Integer` | Integer | Moment | `defaultValue: 20`, `input.stepSize: 10` |
| `Decimal` | Decimal | Period | |
| `Money` | Money | CalendarPeriod | |
| `Money en-US` | Money | CalendarPeriod | `culture: en-US` |
| `Money de-DE` | Money | CalendarPeriod | `culture: de-DE` |
| `Percent` | Percent | CalendarPeriod | |
| `Boolean` | Boolean | CalendarPeriod | |
| `BooleanCheckBox` | Boolean | CalendarPeriod | `input.check: true` |
| `Weekday` | Weekday | CalendarPeriod | |
| `Month` | Month | CalendarPeriod | |
| `Year` | Year | CalendarPeriod | |
| `LookupDecimal` | Money | Period | `lookupName: Commission` |
| `None` | None | CalendarPeriod | |

### All Value Types Mandatory
Same value types with `valueMandatory: true`, including switch and checkbox variants.

---

## Time Types

### All Time Types
Every time type shown with a Money field:

| Field | TimeType | Notes |
|:--|:--|:--|
| `Money.Moment` | Moment | DateTimePicker for start |
| `Money.Period` | Period | DateTimePicker for start + end |
| `Money.ClosedPeriod` | Period | `endMandatory: true` |
| `Money.ClosedPeriod.Mandatory` | Period | `valueMandatory` + `endMandatory` |
| `Money.CalendarPeriod` | CalendarPeriod | |
| `Money.ClosedCalendarPeriod` | CalendarPeriod | `endMandatory: true` |
| `Money.Timeless` | Timeless | |

---

## Lists

### Lists
Inline list inputs with optional alias mapping (display label ≠ stored value):

| Field | ValueType | Pattern |
|:--|:--|:--|
| `StringList` | String | Direct list |
| `StringAliasList` | String | Display labels → different stored values |
| `IntegerList` | Integer | Numeric list with default selection |
| `IntegerAliasList` | Integer | String labels → integer values |
| `DecimalList` | Decimal | 5-step decimal list |
| `BooleanList` | Boolean | `"Enabled"/"Disabled"` → true/false |
| `DateList` | Date | ISO date list with default selection |
| `DateAliasList` | Date | String labels → ISO date values |
| `DateTimeList` | DateTime | DateTime list |

---

## Lookups

Three lookups are defined in the regulation:

| Lookup | Pattern |
|:--|:--|
| `Location` | Object lookup — key = postal code, fields: `number`, `name`, with Italian localizations |
| `Commission` | Range lookup — income brackets → commission `factor` |
| `SimpleLookupValues` / `MultiLookupValues` | Object lookups for list binding demos |

---

## Case Slots

Three-level slot hierarchy driven by a `ChildCount` field:

```
SlotParent (ChildCount: 1–3)
  └─ SlotChild [slot 1] → SlotChildChild [slot 1.A, 1.B]
  └─ SlotChild [slot 2] → SlotChildChild [slot 2.A, 2.B]
  └─ SlotChild [slot 3] → SlotChildChild [slot 3.A, 3.B]
```

- `SlotChild` slots appear based on `ChildCount` via `buildExpression` on `CaseRelation`
- Each child slot carries `ChildName` (String) and `Child.Birthdate` (Date)
- `SlotChildChild` carries `ChildChildName` per sub-slot

---

## Case Relations

| Source | Target | Condition |
|:--|:--|:--|
| `SlotParent` | `SlotChild [1]` | `ChildCount` in [1, 3] |
| `SlotParent` | `SlotChild [2]` | `ChildCount` in [2, 3] |
| `SlotParent` | `SlotChild [3]` | `ChildCount` in [3, 3] |
| `SlotChild [1–3]` | `SlotChildChild [n.A / n.B]` | unconditional |
| `All Value Types` | `All Time Types` | unconditional |
| `Conditions.Base` | `Conditions.Double` | double source value; validate even divisibility |
| `Conditions.Base` | `Conditions.Positive` | only when base > 0; copy start/end |
| `Conditions.Double` | `Conditions.SecondLevel` | only when double > 100 |
| `Wage` | `Allowance` | 10 % allowance when wage > 5 000 |
| `Simple Lookups` | `Multi Lookups` | unconditional |

---

## Case Actions

### Build Actions (No-Code)
| Case / Field | Action | Effect |
|:--|:--|:--|
| `CaseFieldBooleanAction.BooleanAction` | `Input.SetEndMonthPicker` | Month picker for end date |
| | Conditional `SetFieldValue` | Value = 1 if first day of month, else 2 |
| | Conditional `Input.DisableValue` | Disable input on first day of month |
| `CaseActionPeriod.PeriodAction` | `Input.SetStartTimePicker` + `Input.SetEndTimePicker` | Time pickers; disable value; set to period duration in days |
| `CaseActionLookup.LookupAction` | `SetValue($SimpleLookupValues.Lookup.String(202,name))` | Lookup field by key |
| `CaseActionRangeLookup.RangeLookupAction` | `SetValue($SimpleLookupValues.RangeLookup.String(2.5,name))` | Range lookup by value |
| `CaseFieldAction` (multiple) | Attribute reads, conditional chains, AddPeriod | Demonstrates full action expression grammar |

### Validate Actions (No-Code)
| Field | Action |
|:--|:--|
| `Conditions.Double` | Only odd values allowed (validateExpression) |
| `MinValue` | `ValueGreaterThan(1500)` + `ValueLessThan(#MaxValue)` |
| `MaxValue` | `ValueLessThan(8000)` + `ValueGreaterThan(#MinValue)` |
| `Email` | `Email` — built-in format validation |
| `Period` | Start/end range checks + `ValueGreaterThan(@Period?)` |
| `ConditionalTrigger` | Multi-branch conditional validate actions |

### Available Actions (No-Code)
| Case | Action |
|:--|:--|
| `CaseAvailableActionOn` | `? ^^CaseAvailableToggle != 1` |
| `CaseAvailableActionOff` | `? ^^CaseAvailableToggle == 1` |

---

## Scripts

| Script | Function type | Purpose |
|:--|:--|:--|
| `MyCaseChangeFunction.cs` | CaseChange | Custom case change handler |
| `MyCaseValidateFunction.cs` | CaseValidate | Custom case validation handler |

---

## Other Features

| Feature | Case |
|:--|:--|
| `hidden: true` | `HiddenCase` — not visible in UI |
| `baseCase` on hidden case | `HiddenBaseCase` — extends a hidden case |
| `overrideType: Inactive` | `OverrideInactive` — case deactivated via override |
| `cancellationType: Case` | `Conditions.Base` — entire case cancelled |
| `input.icon` + `input.priority` | `All Value Types`, `All Time Types` |
| `input.startLabel/endLabel/valueLabel` | `LabelAndHelp` — full label/help/required customization |
| `startDateType/endDateType` | `CaseFieldDateTypeMonth`, `CaseFieldDateTypeYear` |
| `input.startPicker/endPicker` | `StartPickerEndPicker` — picker type variants |
| Lookup binding | `MandatoryLookupString`, `MandatoryLookupDecimal` |
| Culture-specific money | `MoneyCulture.MoneyWithCutlure` (`culture: de-DE`) |
| Toggle with conditional fields | `Toggle` — shows `ToggleReasonOn` or `ToggleReasonOff` |

---

## Files

| File | Purpose |
|:--|:--|
| `Payroll.json` | Complete regulation, cases, lookups, relations, scripts |
| `scripts/MyCaseChangeFunction.cs` | CaseChange script |
| `scripts/MyCaseValidateFunction.cs` | CaseValidate script |
| `Setup.pecmd` | Full setup: delete + import |
| `Import.pecmd` | Import without delete |
| `Delete.pecmd` | Remove the CaseDefPayroll tenant |

## Commands

```
# Full setup
Setup.pecmd

# Re-import without delete
Import.pecmd

# Teardown
Delete.pecmd
```

## Web Application Login

| Field | Value |
|:--|:--|
| User | `lucy.smith@foo.com` |
| Password | `@ayroll3nginE` |
