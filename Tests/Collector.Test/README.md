# Collector.Test

Payrun tests covering collector features: multi-source accumulation, result capping (`maxResult`),
result flooring (`minResult`), and sign negation (`negated`).

## Collectors

| Collector | Feature | Config | What is tested |
|:----------|:--------|:-------|:---------------|
| `GrossWage` | Multi-source accumulation | plain | Two wage types (Salary + Bonus) feed the same collector |
| `SocialBase` | Upper cap | `maxResult: 3000` | Accumulated value above max is capped to 3000 |
| `MinWageBase` | Lower floor | `minResult: 2000` | Accumulated value below min is floored to 2000 |
| `NegatedDeduction` | Sign negation | `negated: true` | Incoming value is stored as its negative |

## Wage Types

| WT | Name | Collectors | Purpose |
|---:|:-----|:-----------|:--------|
| 101 | Salary | GrossWage, SocialBase, MinWageBase | Feeds three collectors simultaneously |
| 102 | Bonus | GrossWage only | Second source for GrossWage — not subject to SocialBase or MinWageBase limits |
| 201 | Deduction | NegatedDeduction | Feeds negated collector |

## Jobs

| Job | Period | Salary | Bonus | Deduction | Scenario |
|:----|:-------|-------:|------:|----------:|:---------|
| `Jan24` | Jan 2024 | 1 000 | 500 | 300 | **minResult active**: Salary < 2000 → MinWageBase floored to 2000 |
| `Feb24` | Feb 2024 | 2 500 | 1 000 | 300 | **Normal range**: all collectors within limits |
| `Mar24` | Mar 2024 | 4 000 | 2 000 | 300 | **maxResult active**: Salary > 3000 → SocialBase capped to 3000 |

## Expected Results

### Jan24

| Collector | Salary | Bonus | Raw sum | Result | Reason |
|:----------|-------:|------:|--------:|-------:|:-------|
| GrossWage | 1 000 | 500 | 1 500 | **1 500** | Multi-source: Salary + Bonus |
| SocialBase | 1 000 | — | 1 000 | **1 000** | Below maxResult(3000) |
| MinWageBase | 1 000 | — | 1 000 | **2 000** | Below minResult(2000) → floored |
| NegatedDeduction | — | — | 300 | **-300** | Negated |

### Feb24

| Collector | Result | Reason |
|:----------|-------:|:-------|
| GrossWage | **3 500** | 2 500 + 1 000 |
| SocialBase | **2 500** | Below maxResult(3000) |
| MinWageBase | **2 500** | Above minResult(2000) |
| NegatedDeduction | **-300** | Negated |

### Mar24

| Collector | Salary | Bonus | Raw sum | Result | Reason |
|:----------|-------:|------:|--------:|-------:|:-------|
| GrossWage | 4 000 | 2 000 | 6 000 | **6 000** | Multi-source, no limit |
| SocialBase | 4 000 | — | 4 000 | **3 000** | Above maxResult(3000) → capped |
| MinWageBase | 4 000 | — | 4 000 | **4 000** | Above minResult(2000) |
| NegatedDeduction | — | — | 300 | **-300** | Negated |

## Run

```cmd
Collector.Test/Test.pecmd
```

Add to `Test.All.pecmd`:

```
Collector.Test/Test.pecmd
```
