# Sync NuGet.org

Pushes one or more PayrollEngine NuGet packages from GitHub Packages to NuGet.org.
This workflow is intentionally separate from the release orchestrator — NuGet.org
synchronisation is a deliberate, manual step that happens after a GitHub release
has been verified.

---

## Trigger

**Manual only** (`workflow_dispatch`).

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `lib_version` | ✅ | — | Version to sync (e.g. `1.0.0`, `0.10.0-beta.1`) |
| `packages` | — | `all` | Which packages to sync (see [Package Filter](#package-filter)) |

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `PAT_DISPATCH` | Organisation-level | Read GitHub Packages and GitHub Release assets |
| `NUGET_ORG_API_KEY` | `PayrollEngine` repo only | Push packages to NuGet.org |

---

## Package Filter

The `packages` input accepts a suffix of the package name after `PayrollEngine.`:

| Value | Packages synced |
|-------|-----------------|
| `all` | All 7 packages |
| `Core` | `PayrollEngine.Core` only |
| `Serilog` | `PayrollEngine.Serilog` only |
| `Document` | `PayrollEngine.Document` only |
| `Client` | All 4 `PayrollEngine.Client.*` packages |
| `Client.Core` | `PayrollEngine.Client.Core` only |
| `Client.Scripting` | `PayrollEngine.Client.Scripting` only |
| `Client.Test` | `PayrollEngine.Client.Test` only |
| `Client.Services` | `PayrollEngine.Client.Services` only |

The filter uses suffix matching: `Core` matches only `PayrollEngine.Core`, not
`PayrollEngine.Client.Core`. `Client` matches all four `Client.*` packages.

If the filter matches no packages, the workflow fails immediately with a clear error message.

---

## What the Workflow Does

For each matched package:

1. **Locate release** — calls `repos.getReleaseByTag` on the package's repository
   for tag `v{lib_version}`. Fails this package if the release does not exist.

2. **Find `.nupkg` asset** — scans the release assets for a file ending in `.nupkg`.
   Fails this package if no asset is found.

3. **Download asset** — downloads the `.nupkg` binary via the GitHub Releases asset
   API with `application/octet-stream` accept header. Writes to a temp directory.

4. **Push to NuGet.org** — calls `dotnet nuget push` via `spawnSync` with
   `--skip-duplicate`. The NuGet API key is passed as a CLI argument; `spawnSync`
   does not write its argv array to the Actions log, so the key is not exposed in
   run output.

Packages are processed sequentially. A failure on one package is recorded but does not
stop the remaining packages — all errors are collected and reported together at the end.
The workflow fails if any package failed.

---

## Output

A summary is printed at the end of the run:

```
═══════════════════════════════════════════
  NuGet.org Sync Summary
═══════════════════════════════════════════
  Synced: 6/7

  Failed:
    ❌ PayrollEngine.Serilog: Release v1.0.0 not found
```

Exit is `success` only if all matched packages were pushed without error.

---

## `--skip-duplicate` Behaviour

`dotnet nuget push --skip-duplicate` treats an already-published version as a
non-error — the push exits `0` and logs a warning. This means re-running the
workflow for the same version is safe and idempotent.

---

## Relationship to Orchestrate Release

```
orchestrate-release.yml
  └── publishes to GitHub Packages (ghcr.io / nuget.pkg.github.com)
        └── [manual, after verification]
              sync-nuget-org.yml
                └── pushes to NuGet.org
```

The separation is intentional: NuGet.org packages are immutable once published.
The GitHub Packages release is verified first; only then is NuGet.org updated.

---

## Permissions

```yaml
permissions:
  contents: read     # read release assets from this repo
  packages: read     # read GitHub Packages metadata
```

GitHub Release asset downloads and NuGet pushes use `PAT_DISPATCH` and
`NUGET_ORG_API_KEY` respectively.
