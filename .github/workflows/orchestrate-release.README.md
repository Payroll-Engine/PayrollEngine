# Orchestrate Release

Coordinates a full PayrollEngine release across all repositories in the correct
dependency order. A single manual trigger dispatches builds to up to 10 repositories,
waits for each wave to publish its NuGet packages before starting the next, and
finally creates an umbrella GitHub Release in this repository.

---

## Trigger

**Manual only** (`workflow_dispatch`).

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `lib_version` | ✅ | — | Shared version for all 7 library repos (e.g. `1.0.0`, `0.10.0-beta.1`) |
| `backend_version` | — | _(skip)_ | Version for `PayrollEngine.Backend` — leave empty to skip |
| `console_version` | — | _(skip)_ | Version for `PayrollEngine.PayrollConsole` — leave empty to skip |
| `webapp_version` | — | _(skip)_ | Version for `PayrollEngine.WebApp` — leave empty to skip |
| `update_wiki` | — | `false` | Update the Wiki Releases page _(deprecated — website replaces wiki)_ |
| `dry_run` | — | `false` | Run in dry-run mode (see [Dry Run](#dry-run)) |

Pre-release versions follow SemVer: `{major}.{minor}.{patch}-{label}.{n}` (e.g. `1.0.0-beta.1`).
Pre-release status is detected **per component** — libraries and apps are evaluated independently.

---

## Required Secrets

| Secret | Scope | Purpose |
|--------|-------|---------|
| `PAT_DISPATCH` | Organisation-level | Classic PAT with `repo`, `packages:read`, `packages:write`, `delete:packages` scopes across all repos |

---

## Job Pipeline

```
prepare
  ├── version-guard          (skipped in dry-run)
  ├── breaking-change-guard  (skipped in dry-run)
  │
  ├── wave-1-core
  │     wait-wave-1  ─── NuGet: Core ✓
  │
  ├── wave-2-serilog ──┐
  ├── wave-2-document ─┼── parallel
  ├── wave-2-client-core ─┘
  │     wait-wave-2  ─── NuGet: Serilog, Document, Client.Core ✓
  │
  ├── wave-3-scripting ──┐
  ├── wave-3-test ────────┘── parallel
  │     wait-wave-3  ─── NuGet: Client.Scripting, Client.Test ✓
  │
  ├── wave-4-services
  │     wait-wave-4  ─── NuGet: Client.Services ✓
  │
  ├── wave-5-backend ──┐
  ├── wave-5-console ──┼── parallel, conditional
  ├── wave-5-webapp ───┘
  │     wait-wave-5  ─── GitHub Releases: Backend, Console, WebApp ✓
  │
  └── create-umbrella-release
        update-wiki  (deprecated, skipped unless update_wiki=true)
```

---

## Jobs

### `prepare`

Resolves and validates all input parameters. Sets outputs consumed by every downstream job:

| Output | Description |
|--------|-------------|
| `lib_version` | Effective library version (`0.0.0-dryrun.{run}` in dry-run) |
| `lib_prerelease` | `true` if `lib_version` contains a hyphen |
| `build_backend/console/webapp` | `true` if the corresponding version input was provided |
| `backend/console/webapp_prerelease` | Pre-release flag per app |
| `any_prerelease` | `true` if any component is pre-release |
| `dry_run` | Passed through from input |

Also prints a human-readable release plan to the log.

---

### `version-guard` _(skipped in dry-run)_

Checks **all** target repos upfront before any build starts. Fails immediately if any
version already exists, preventing a partial release that would require manual cleanup.

Checks per library repo (7 repos × 3 checks):
- Git tag `v{lib_version}` does not exist
- GitHub Release `v{lib_version}` does not exist
- NuGet package `{version}` does not exist on GitHub Packages (`per_page: 100`)

Checks per app repo (only for provided versions, 3 checks each):
- Git tag `v{app_version}` does not exist
- GitHub Release `v{app_version}` does not exist
- Docker image tag `{app_version}` does not exist on `ghcr.io`

Checks umbrella:
- GitHub Release `v{lib_version}` does not exist in this repo

On any conflict: lists **all** conflicts before failing — never stops at the first error.

---

### `breaking-change-guard` _(skipped in dry-run)_

Runs `devops/scripts/Update-BreakingChanges.ps1` against `HEAD~1` across:
- `PayrollEngine.Backend` (REST API + .NET models)
- `PayrollEngine.Client.Scripting` (.NET API surface)
- `PayrollEngine.Client.Services` (.NET API surface)

**Exit code behaviour:**

| Exit code | Meaning | Action |
|-----------|---------|--------|
| `0` | No breaking changes | Continue |
| `1` | Breaking changes detected | Check `RELEASE_NOTES.md` for `breaking change` — block if absent |
| `2` | Infrastructure failure (build/git/tool error) | Always block — detection result unreliable |

The breaking-change report is uploaded as artifact `breaking-change-report` regardless of outcome.

---

### `wave-1-core` / `wait-wave-1`

Dispatches a `release` event to `PayrollEngine.Core` with payload:

```json
{
  "version": "1.0.0",
  "wave": "1",
  "is_prerelease": "false",
  "dry_run": "false"
}
```

Then polls the GitHub Packages NuGet API until `PayrollEngine.Core {version}` appears.
Adds a 10 s propagation buffer after detection before releasing the next wave.

**Poll parameters:** `per_page: 100`, max 60 attempts × 15 s = **15 min timeout**.

---

### `wave-2-*` / `wait-wave-2`

Parallel dispatch to `PayrollEngine.Serilog`, `PayrollEngine.Document`,
`PayrollEngine.Client.Core`. All three dispatches must succeed before `wait-wave-2` starts.
`wait-wave-2` polls all three packages sequentially, each with its own 15-min timeout.

---

### `wave-3-*` / `wait-wave-3`

Parallel dispatch to `PayrollEngine.Client.Scripting`, `PayrollEngine.Client.Test`.
Same polling pattern — 15-min timeout per package.

---

### `wave-4-services` / `wait-wave-4`

Single dispatch to `PayrollEngine.Client.Services`.
15-min timeout.

---

### `wave-5-*` / `wait-wave-5`

Conditional parallel dispatch to the three app repos — only if the corresponding version
input was provided. Each app resolves its own version independently (dry-run version or
real input).

`wait-wave-5` polls `repos.listReleases` for each dispatched app until the release tag
appears. **Poll parameters:** max 90 attempts × 15 s = **22.5 min timeout per app**.

In dry-run, `wait-wave-5` returns immediately — app releases are drafted only and not polled.

---

### `create-umbrella-release` _(skipped in dry-run)_

Creates the umbrella GitHub Release in this repository (`PayrollEngine`) tagged `v{lib_version}`.

**Release body contains:**
- Full content of `RELEASE_NOTES.md` (fallback: `Release v{version}` if file missing or empty)
- Auto-generated NuGet packages table with links to GitHub Packages and NuGet.org
- Auto-generated Docker images table (only if app versions were provided)

**swagger.json attachment logic:**
1. Download `swagger.json` from the Backend GitHub Release asset
2. Check file presence on disk (`swagger_check` step)
3. Attach to umbrella release **only if**: `build_backend == true` AND `wait-wave-5 == success` AND file exists on disk

Release notes content is passed via `RELEASE_NOTES_CONTENT` env var (not inline interpolation)
to avoid YAML/JS parse errors when the content contains backticks or `${}` expressions.

---

### `update-wiki` _(deprecated)_

Runs only if `update_wiki == true`. Prepends a new version section to `wiki/Releases.md`
and pushes to the Wiki repository. Kept for manual override — the website replaces the
Wiki as primary release documentation.

---

## Wait Job Error Handling

All five wait jobs use consistent error handling:

| Error | Behaviour |
|-------|-----------|
| `401 Unauthorized` | Fail immediately — PAT expired or missing |
| `403 Forbidden` | Fail immediately — insufficient PAT scopes |
| `404 Not Found` | Retry silently — package/release not yet available |
| `5xx / network` | Log warning, retry silently |

This ensures a PAT expiry surfaces within seconds rather than consuming the full
15–22 min timeout.

---

## Dry Run

When `dry_run = true`:

| Behaviour | Description |
|-----------|-------------|
| Version | All repos receive `0.0.0-dryrun.{run_number}` instead of real inputs |
| Apps | All 3 app repos are always built regardless of version inputs |
| `version-guard` | Skipped |
| `breaking-change-guard` | Skipped |
| Releases | All repos create **draft** releases with the synthetic version |
| `wait-wave-5` | Returns immediately — draft releases are not polled |
| `create-umbrella-release` | Skipped |

The synthetic version `0.0.0-dryrun.{run_number}` never conflicts with a real release
and is safe to accumulate across repeated test runs.

---

## Versioning Rules

| Scope | Rule |
|-------|------|
| Libraries (7 repos) | Single shared `lib_version` for all |
| Apps (3 repos) | Independent version per app — omit input to skip that app |
| Pre-release detection | Per component — stable libraries can coexist with pre-release apps in the same run |

---

## Permissions

```yaml
permissions:
  contents: write    # create releases and tags in this repo
  packages: read     # read GitHub Packages for version guard and wait-polling
```

Cross-repo operations (dispatch, clone, package access) use `PAT_DISPATCH`.
