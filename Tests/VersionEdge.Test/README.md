# VersionEdge.Test

Tests the **boundary behaviour of regulation `validFrom`** against the payrun
`evaluationDate` — specifically the two cases left uncovered by
`VersionPayroll.Test`:

| Scenario | `validFrom` | `evaluationDate` | Expected |
|:---------|:-----------|:----------------|:---------|
| Same-day activation | 2024-02-01 | **2024-02-01** | New version **active** (`<=`) |
| Future version | 2024-03-01 | **2024-02-28** | New version **not yet active** (`>`) |

`VersionPayroll.Test` covers normal sequencing (evalDate well inside a version's
validity window). This test isolates the exact boundary.

---

## Scenario

**Regulation:** `VersionEdge.Test` (3 versions)  
**Tenant:** `VersionEdge.Test` | **Division:** `VersionEdgeDivision` (de-CH)  
**Employee:** `felix.huber@versionedge.test`

### Regulation Versions

| Version | `validFrom` | `created` | WT101 value |
|--------:|:-----------|:---------|------------:|
| 1 | *(none — always active)* | 2023-12-01 | 1 000 |
| 2 | 2024-02-01 | 2024-01-15 | 2 000 |
| 3 | 2024-03-01 | 2024-02-10 | 3 000 |

### Derivation Rule

A regulation version is active for a given payrun if:

```
version.validFrom <= evaluationDate   (or validFrom is null)
```

---

## Payrun Jobs

### Job 1 — `Jan24`

| | |
|:--|:--|
| `periodStart` | 2024-01-01 |
| `evaluationDate` | **2024-01-28** |
| Active version | **V1** — V2 not yet valid (Feb 1 > Jan 28) |
| WT101 | **1 000** |

### Job 2 — `Feb24` (same-day boundary)

| | |
|:--|:--|
| `periodStart` | 2024-02-01 |
| `evaluationDate` | **2024-02-01** |
| Active version | **V2** — `validFrom == evaluationDate` → `<=` includes it |
| WT101 | **2 000** |

> Key assertion: `validFrom == evaluationDate` activates the version.
> A strict `<` operator would incorrectly keep V1 for this job.

### Job 3 — `Mar24` (future version not active)

| | |
|:--|:--|
| `periodStart` | 2024-03-01 |
| `evaluationDate` | **2024-02-28** |
| Active version | **V2** — V3's `validFrom` (Mar 1) > evalDate (Feb 28) |
| WT101 | **2 000** |

> Key assertion: V3 must **not** be derived. An off-by-one error would
> incorrectly apply V3 (value 3 000) here.

---

## Key Assertions

| Assertion | Verified by |
|:----------|:------------|
| `validFrom == evaluationDate` activates the version | Feb job returns 2 000, not 1 000 |
| `validFrom > evaluationDate` keeps prior version active | Mar job returns 2 000, not 3 000 |
| Normal sequencing still works | Jan job returns 1 000 |

---

## Relation to VersionPayroll.Test

`VersionPayroll.Test` runs Jan/Feb/Mar 2019 with `evaluationDate` in the middle
of each month — the version selection is unambiguous in all three jobs.
`VersionEdge.Test` deliberately places `evaluationDate` at the exact `validFrom`
boundary to exercise the `<=` comparison directly.

---

## Running the Test

```cmd
cd Tests\VersionEdge.Test
pecmd Test.pecmd
```

## See Also

- [VersionPayroll.Test](../VersionPayroll.Test/) — normal version sequencing
- [PayrunEdge.Test](../PayrunEdge.Test/) — other temporal boundary cases
