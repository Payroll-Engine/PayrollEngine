# GlobalPayroll — LLM Prompt

This file documents the natural language requirements that served as the input for generating the GlobalPayroll regulation. It represents **Phase 1** of the LLM-assisted development workflow.

---

## Requirements (Input)

> Create a Payroll Engine regulation for **GlobalTech**, a fictitious technology company.
> The regulation must be country-neutral and work without any external dependencies.
>
> **Employment model**
> - Each employee has a monthly base salary and an employment level (1.0 = full-time, 0.6 = 60%, etc.)
> - Base salary is scaled by the employment level
>
> **Supplements**
> - Employees aged 50 or older receive a senior supplement of 5% on the base salary
> - The age check must be based on the employee's date of birth
>
> **Bonus**
> - A one-time performance bonus can be paid in a specific month
> - The bonus must not carry over into other periods — it applies to exactly one pay period
>
> **Deductions**
> - Progressive income tax using a bracket lookup table:
>   - up to 3 000: 10%
>   - up to 6 000: 18%
>   - up to 10 000: 25%
>   - above 10 000: 32%
> - Social security: 10% on gross income (national rate)
> - Health insurance: 5% on gross income (company rate)
>
> **Test employees**
>
> | Employee | Salary | Level | Born | Notes |
> |---|---|---|---|---|
> | Sarah Chen | 6 000 | 100% | 1985-08-20 | Performance bonus of 1 000 in January 2024 |
> | Carlos Rodriguez | 10 000 | 60% | 1970-07-15 | No bonus |
>
> **Test coverage**
> - January 2024: Sarah with bonus, Carlos with senior supplement
> - February 2024: Verify that Sarah's bonus does **not** appear (Moment time type validation)

---

## What the LLM Generated

From this prompt, the following files were generated:

| File | Content |
|:--|:--|
| `Payroll.json` | Regulation with cases, lookups, wage types, collectors, payroll and payrun |
| `Payroll.Values.json` | Employee case values (salary, employment level, birth date, bonus) |
| `Payroll.Jobs.json` | Payrun job invocations for Jan–Mar 2024 |
| `Test.et.json` | Employee payroll test for Jan 2024 (bonus) and Feb 2024 (no bonus) |

---

## Human Corrections

After generation, the following points required human domain review:

| Point | Issue | Correction |
|:--|:--|:--|
| Senior supplement | Age boundary check (≥ 50 vs > 50) | Verified — `>= 50` is correct |
| Moment bonus | Feb test initially missing | Added Feb 2024 test job to verify Moment scoping |
| Tax bracket boundary | Bracket3 at exactly 6 000 | Confirmed — `rangeValue: 6000` means "from 6 000 inclusive" |
| EmploymentLevel type | Generated as `Decimal` | Corrected to `Percent` (PE convention) |

---

> See the [LLM-Assisted Regulation Development](../../docs/AdvancedTopics/TestDrivenPayrollSoftware.md) concept for the full workflow description.
