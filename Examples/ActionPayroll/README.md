# ActionPayroll Example

A practical custom case action example for **ActionTenant**, demonstrating how to
implement a reusable case validation action with localized issue messages and an
input mask.

The example validates a structured employee registration number using an ISO 7064
check digit algorithm — implemented as a custom `CaseValidate` action callable
directly from No-Code `validateActions`.

---

## Scenario

One employee case (`EmployeeRegistration`) with two fields:

| Field | ValueType | TimeType | Notes |
|:--|:--|:--|:--|
| `Mandatory` | String | Period | `endPickerOpen: month` — month picker for period end |
| `RegistrationNumber` | String | Period | `input.valueMask: "REG-000.000.000"` · `valueMandatory: true` |

The `RegistrationNumber` field accepts structured registration numbers in the format
`REG-000.000.000`. On save, the custom `CheckRegistrationNumber` action validates
the check digit and raises an issue if the value is invalid or missing.

---

## Custom Action: `CheckRegistrationNumber`

Defined in `Scripts/CaseValidateFunction.cs`, registered as a `CaseValidate` script.

```csharp
[CaseValidateAction("CheckRegistrationNumber", "Validate a structured registration number with ISO 7064 check digit")]
public bool CheckRegistrationNumber(string caseFieldName, string registrationNumber)
```

**Called from No-Code** in `validateActions`:
```
? CheckRegistrationNumber('RegistrationNumber', ^:RegistrationNumber)
```

### Validation logic

1. Strips `REG-` prefix and dots to extract the 9-digit check value
2. Applies ISO 7064 Mod 11 Radix 1 check digit verification (`CheckDigit(11, 1, ...)`)
3. On success: logs `Valid registration number` and returns `true`
4. On failure: adds a localized case issue and returns `false`

### Action Issues

Defined with `[ActionIssue]` attributes; issue texts stored in the
`MyActions.Action` lookup for localization:

| Issue key | Parameters | Message |
|:--|:--|:--|
| `MissingRegistrationNumber` | — | "Missing registration number" |
| `InvalidRegistrationNumber` | `(0)` field name, `(1)` value | "(0) with invalid registration number: (1)" |

German localization via `MyActions.Action` lookup:
```json
{ "key": "InvalidRegistrationNumber", "value": "(0) is invalid: (1)", "valueLocalizations": { "de": "(0) ist ungültig: (1)" } }
```

---

## Case Test

`Test.ct.json` defines two `CaseValidate` test cases:

| Test | Value | Expected result |
|:--|:--|:--|
| `RegistrationNumber.Valid.999999996.Test` | `999999996` | Valid — value accepted |
| `RegistrationNumber.Invalid.999999997.Test` | `999999997` | Invalid — issue `CaseInvalid` (400) on `RegistrationNumber` field |

---

## Key Design Decisions

### Custom action as reusable validation component
The `CheckRegistrationNumber` method is annotated with `[CaseValidateAction]` and
`[ActionParameter]` attributes. This registers it as a named, discoverable action
callable from any regulation's `validateActions` list using No-Code syntax —
no expression scripting required at the call site.

### Localized issues via action lookup
Issue messages are not hardcoded in the script. They are stored in the
`MyActions.Action` lookup with `valueLocalizations` per language. The engine
resolves the active culture at runtime and displays the correct message in the UI.

### ISO 7064 check digit via `CheckDigit` API
The scripting API provides a `CheckDigit` class supporting configurable modulus,
radix, character-set, and double-check-digit variants. Standard presets
(`Mod11Radix2`, `Mod97Radix10`, etc.) are also available as static properties.

---

## Files

| File | Purpose |
|:--|:--|
| `Payroll.json` | Tenant, regulation, lookup, case, script registration |
| `Scripts/CaseValidateFunction.cs` | Custom `CheckRegistrationNumber` action implementation |
| `Test.ct.json` | Case test: valid and invalid registration number |
| `Setup.pecmd` | Full setup: delete + import + set password |
| `Delete.pecmd` | Remove the ActionTenant |
| `Test.pecmd` | Run case test |

## Commands

```
# Full setup
Setup.pecmd

# Run case test
Test.pecmd

# Teardown
Delete.pecmd
```

## Web Application Login

| Field | Value |
|:--|:--|
| User | `lucy.smith@foo.com` |
| Password | `@ayroll3nginE` |
