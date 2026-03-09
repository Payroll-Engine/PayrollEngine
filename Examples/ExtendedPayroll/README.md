# ExtendedPayroll Example

A practical composite function example for **ExtendedTenant**, demonstrating how
to extend the engine's built-in scripting functions with custom C# classes.

This is the reference implementation for the
[Extended Functions](https://github.com/Payroll-Engine/PayrollEngine/wiki/Extended-Functions)
wiki tutorial.

---

## Scenario

One employee, one wage type. The `Salary` value is not read directly via a
No-Code expression — it is delegated to a composite function class, demonstrating
the full three-step pattern for function extension.

| Employee | Salary | Period |
|:--|:--|:--|
| Mario Nuñez | 5 000 | January 2023 |

---

## Composite Function Pattern

Function extension involves three steps:

### Step 1 — Implement business logic (`CompositeWageTypeValueFunction.cs`)

A plain C# class that receives `WageTypeValueFunction` as a constructor argument
and exposes domain methods:

```csharp
public class CompositeWageTypeValueFunction(WageTypeValueFunction function)
{
    private WageTypeValueFunction Function { get; } = function
        ?? throw new ArgumentNullException(nameof(function));

    public decimal GetSalary()
    {
        return Function.CaseValue["Salary"];
    }
}
```

### Step 2 — Register the extension (`WageTypeValueFunction.cs`)

Extend the engine's `WageTypeValueFunction` using `partial` to expose the
composite class as a named property:

```csharp
public partial class WageTypeValueFunction
{
    private CompositeWageTypeValueFunction function;
    public CompositeWageTypeValueFunction MyRegulation => function ??= new(this);
}
```

The property `MyRegulation` is now available in every `valueExpression` of this
regulation — lazy-initialized on first access.

### Step 3 — Call from wage type (`Payroll.json`)

The composite method is called directly from the wage type `valueExpression`:

```json
{
  "wageTypeNumber": 100,
  "name": "Salary",
  "valueExpression": "MyRegulation.GetSalary()"
}
```

---

## Regulation: ExtendedRegulation

### Cases

| Case | Type | Field | ValueType | TimeType |
|:--|:--|:--|:--|:--|
| `Salary` | Employee | Salary | Money | CalendarPeriod |

### Wage Types

| # | Name | ValueExpression | Collector |
|:--|:--|:--|:--|
| 100 | Salary | `MyRegulation.GetSalary()` | — |

### Scripts

| Script | Function type | File |
|:--|:--|:--|
| `CompositeWageTypeValueFunction` | WageTypeValue | `Scripts/CompositeWageTypeValueFunction.cs` |
| `WageTypeValueFunction` | WageTypeValue | `Scripts/WageTypeValueFunction.cs` |

---

## Test Result — January 2023

| Employee | WT 100 Salary |
|:--|:--|
| Mario Nuñez | 5 000 |

---

## Key Design Decisions

### Composite vs. Extension Method
The composite pattern wraps `WageTypeValueFunction` in a separate class rather
than adding extension methods directly. This allows grouping multiple related
methods under a named namespace (`MyRegulation`) and enables full IDE support —
IntelliSense, refactoring, and debugger step-through — when developing regulation
logic in Visual Studio.

### Lazy initialization via `??=`
`MyRegulation => function ??= new(this)` creates the composite instance on first
access and reuses it for subsequent calls within the same wage type evaluation.
This avoids repeated construction without requiring manual lifecycle management.

### Reuse across derived regulations
Because the composite class is a plain C# type injected via constructor, higher-level
regulations can subclass or wrap it — keeping shared calculation logic in the base
regulation while country- or client-specific logic lives in derived layers.

---

## Files

| File | Purpose |
|:--|:--|
| `Payroll.json` | Tenant, regulation, case, wage type, script registrations |
| `Scripts/CompositeWageTypeValueFunction.cs` | Business logic class (`GetSalary`) |
| `Scripts/WageTypeValueFunction.cs` | Partial extension — registers `MyRegulation` property |
| `Test.et.json` | Employee payroll test — January 2023, WT 100 = 5 000 |
| `Setup.pecmd` | Full setup: delete + import + set password |
| `Delete.pecmd` | Remove the ExtendedTenant |
| `Test.pecmd` | Run employee payroll test |

## Commands

```
# Full setup
Setup.pecmd

# Run test
Test.pecmd

# Teardown
Delete.pecmd
```

## Web Application Login

| Field | Value |
|:--|:--|
| User | `lucy.smith@foo.com` |
| Password | `@ayroll3nginE` |

## See Also

- [Extended Functions](https://github.com/Payroll-Engine/PayrollEngine/wiki/Extended-Functions) — wiki tutorial this example accompanies
