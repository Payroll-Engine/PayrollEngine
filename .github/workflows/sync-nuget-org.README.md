# Sync NuGet.org

Pushes one or more PayrollEngine NuGet packages from GitHub Packages to NuGet.org.
This workflow is intentionally separate from the release orchestrator — NuGet.org
synchronisation is a deliberate, manual step that happens after a GitHub release
has been verified.

Publishing uses [NuGet.org Trusted Publishing](https://learn.microsoft.com/en-us/nuget/nuget-org/trusted-publishing)
via GitHub Actions OIDC — no long-lived NuGet API key is stored in GitHub Secrets.

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
| `PAT_DISPATCH` | Organisation `Payroll-Engine` | Read GitHub Packages and GitHub Release assets |
| `NUGET_USER` | Organisation `Payroll-Engine` (visibility: `PayrollEngine` repo) | nuget.org profile name (`PayrollEngine`) for `NuGet/login@v1` |

---

## Trusted Publishing Policy

A Trusted Publishing policy on nuget.org must exist for this workflow:

| Field | Value |
|-------|-------|
| Policy owner | PayrollEngine (organisation — owns the packages) |
| Repository owner | `Payroll-Engine` |
| Repository | `PayrollEngine` |
| Workflow file | `sync-nuget-org.yml` |
| Environment | *(empty)* |

**Important:** `NUGET_USER` in GitHub Secrets must be the **nuget.org profile name**
of whoever **created** this policy (visible in the URL at
`https://www.nuget.org/profiles/XXXXX`). NuGet returns HTTP 401 with
*"No matching trust policy owned by user …"* when the wrong username is used.

The policy authorises this workflow to exchange a GitHub OIDC token for a
short-lived NuGet API key (~1 hour). The workflow requests that key immediately
before pushing.

Local or unsupported CI/CD publishing still requires a conventional NuGet API key.

---

## Package Filter

The `packages` input accepts a suffix of the package name after `PayrollEngine.`:

| Value | Packages synced |
|-------|-----------------|
| `all` | All 9 packages |
| `Core` | `PayrollEngine.Core` only |
| `Serilog` | `PayrollEngine.Serilog` only |
| `Document` | `PayrollEngine.Document` only |
| `Client` | All 4 `PayrollEngine.Client.*` packages |
| `Client.Core` | `PayrollEngine.Client.Core` only |
| `Client.Scripting` | `PayrollEngine.Client.Scripting` only |
| `Client.Test` | `PayrollEngine.Client.Test` only |
| `Client.Services` | `PayrollEngine.Client.Services` only |
| `Mcp.Core` | `PayrollEngine.Mcp.Core` only |
| `Mcp.Tools` | `PayrollEngine.Mcp.Tools` only |

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
   `--skip-duplicate`. Authentication uses a short-lived API key obtained from
   `NuGet/login@v1` (Trusted Publishing) immediately before the push step.

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
                └── pushes to NuGet.org (Trusted Publishing)
```

The separation is intentional: NuGet.org packages are immutable once published.
The GitHub Packages release is verified first; only then is NuGet.org updated.

---

## Permissions

```yaml
permissions:
  contents: read     # read release assets from this repo
  packages: read     # read GitHub Packages metadata
  id-token: write    # GitHub OIDC token for Trusted Publishing
```

GitHub Release asset downloads use `PAT_DISPATCH`. NuGet.org authentication uses
Trusted Publishing via `NuGet/login@v1` — no stored NuGet API key.
