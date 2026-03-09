# Contributing to Payroll Engine

Thank you for your interest in contributing to the Payroll Engine!
This document describes how you can get involved.

> 🚧 The Payroll Engine is currently in **pre-release** (`0.y.z`). Breaking changes
> are possible at any time until version 1.0. Please keep this in mind before
> starting any larger contribution.

## Ways to Contribute

Community contributions are currently welcome in the following areas:

| Area | Description |
|:--|:--|
| **Docker** | Improvements to the [Docker Compose stack](https://github.com/Payroll-Engine/PayrollEngine/discussions/2) |
| **CI/CD** | CI/CD integrations across the [repositories](https://github.com/Payroll-Engine/PayrollEngine/wiki/Repositories) |
| **Linux Setup** | Running and [setting up](https://github.com/Payroll-Engine/PayrollEngine/wiki/Setup) the engine on Linux |
| **Web App Localization** | Translations for the [web application](https://github.com/Payroll-Engine/PayrollEngine.WebApp/tree/main/Shared) |
| **Alternative Databases** | Persistence layer implementations for databases other than SQL Server (see [SQL Server implementation](https://github.com/Payroll-Engine/PayrollEngine.Backend/tree/main/Persistence/Persistence.SqlServer) as reference) |

If you are interested in working on one of these areas, please
[contact us](mailto:info@payrollengine.org) before starting, so we can
coordinate and avoid duplicate effort.

## Reporting Issues

Use [GitHub Issues](https://github.com/Payroll-Engine/PayrollEngine/issues)
to report bugs or unexpected behavior. Please include:

- A clear description of the problem
- Steps to reproduce
- Expected vs. actual behavior
- Environment details (.NET version, OS, Docker version if applicable)

> For security vulnerabilities, **do not open a public issue** —
> see [SECURITY.md](SECURITY.md) for the responsible disclosure process.

## Suggesting Features and Asking Questions

Use [GitHub Discussions](https://github.com/Payroll-Engine/PayrollEngine/discussions)
for feature suggestions, questions, and general feedback. This is the preferred
channel for open-ended topics that are not yet actionable as issues.

## Pull Requests

Before opening a pull request, please:

1. Open an issue or discussion to align on the approach
2. Ensure your changes are consistent with the existing code style (.NET / C#)
3. Add or update tests where applicable
4. Keep commits focused and well-described

All contributions must be compatible with the
[MIT License](https://github.com/Payroll-Engine/PayrollEngine/blob/main/LICENSE).

## Development Prerequisites

- [Docker](https://docs.docker.com/get-docker/) — required to run the full stack
- [.NET 10.0 SDK](https://dotnet.microsoft.com/download) — for backend and client development
- See [Container Setup](https://github.com/Payroll-Engine/PayrollEngine/wiki/ContainerSetup)
  for getting the stack running locally

## Code Quality

The repositories use `.editorconfig` and Roslyn Analyzers to enforce a
consistent code style. All analyzer warnings are treated as errors —
your build must be warning-free before opening a pull request.

**Recommended tooling:**

- [JetBrains Rider](https://www.jetbrains.com/rider/) — free for non-commercial use,
  includes full ReSharper analysis inline
- [ReSharper](https://www.jetbrains.com/resharper/) — Visual Studio extension;
  JetBrains offers [free licenses for open-source contributors](https://www.jetbrains.com/community/opensource/)

Both tools surface the same analyzer violations that the CI build enforces.
Using one of them locally saves review cycles.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold these standards.

## Contact

- 📧 Email: [info@payrollengine.org](mailto:info@payrollengine.org)
- 💬 Discussions: [github.com/Payroll-Engine/PayrollEngine/discussions](https://github.com/Payroll-Engine/PayrollEngine/discussions)
- 💖 Sponsorship: [github.com/sponsors/Payroll-Engine](https://github.com/sponsors/Payroll-Engine)
