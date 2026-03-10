<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/Payroll-Engine/PayrollEngine/blob/main/images/logo/NameInversShadow.png">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/Payroll-Engine/PayrollEngine/blob/main/images/logo/NameNormalShadow.png">
    <img alt="Payroll Engine" src="https://github.com/Payroll-Engine/PayrollEngine/blob/main/images/logo/NameNormalShadow.png" width="500px" />
  </picture>
</p>
<p align="center">
  <strong>The open-source payroll automation framework.</strong><br />
  Build multi-country, multi-industry payroll applications with configurable regulation layers.
</p>
<p align="center">
  <a href="https://github.com/Payroll-Engine/PayrollEngine/actions"><img alt="Build" src="https://img.shields.io/github/actions/workflow/status/Payroll-Engine/PayrollEngine/build.yml?logo=github" /></a>
  <a href="https://github.com/Payroll-Engine/PayrollEngine/blob/main/LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-green.svg" /></a>
  <a href="https://github.com/Payroll-Engine/PayrollEngine/releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/Payroll-Engine/PayrollEngine?include_prereleases&logo=github" /></a>
  <a href="https://www.nuget.org/packages/PayrollEngine.Client.Services"><img alt="NuGet" src="https://img.shields.io/nuget/vpre/PayrollEngine.Client.Services?logo=nuget&color=blue" /></a>
  <a href="https://github.com/orgs/Payroll-Engine/packages"><img alt="Docker" src="https://img.shields.io/badge/ghcr.io-images-blue?logo=docker" /></a>
</p>
<p align="center">
  <a href="https://payrollengine.org/docs"><strong>Docs</strong></a> · <a href="https://payrollengine.org/docs/ContainerSetup"><strong>Quick Start</strong></a> · <a href="https://payrollengine.org/docs/Resources"><strong>Resources</strong></a> · <a href="https://github.com/Payroll-Engine/PayrollEngine/releases"><strong>Releases</strong></a> · <a href="https://github.com/Payroll-Engine/PayrollEngine/discussions"><strong>Discussions</strong></a>
</p>

> **This repository** contains the Docker stack, payroll examples, automated tests, JSON schemas, and release artifacts. 
> **Full documentation** — concepts, guides, and API reference — is available at [payrollengine.org](https://payrollengine.org).

---

## What is the Payroll Engine?

The Payroll Engine is a framework for developing payroll applications. It is designed for software companies, payroll service providers, and enterprises that need to automate and scale payroll processing across countries and industries.

The key idea: **payroll logic is not hardcoded**. Instead, business rules are defined in configurable [regulation layers ↗](https://payrollengine.org/docs/Regulations) that can be stacked, overridden, and shared between tenants. This separation of business rules from application code makes the engine adaptable to any country, any industry, and any HR platform.

### Why Payroll Engine?

|                    | Traditional Payroll Software  | Payroll Engine                        |
|:------------------|:-----------------------------|:--------------------------------------|
| **Business rules** | Hardcoded in source code      | Configurable regulation layers        |
| **Multi-country**  | Separate codebases or modules | Stackable country regulations         |
| **Customization**  | Custom development per client | Override layers per tenant            |
| **Testing**        | Manual or integration tests   | Built-in test-driven development      |
| **Deployment**     | Monolithic or SaaS            | Embedded via REST API or Docker       |
| **Time model**     | Overwrites existing data      | Time-stamped values with full history |
| **License**        | Commercial                    | MIT — free for any use                |

## Who Is This For?

The Payroll Engine serves three distinct roles:

| Role          | Description                                                                                                     | Primary Interface                  |
|:-------------|:---------------------------------------------------------------------------------------------------------------|:----------------------------------|
| **Provider**  | Software vendors and payroll service providers who host and operate the engine for their clients                | REST API                           |
| **Regulator** | Payroll domain experts who define and maintain country- or industry-specific calculation rules                  | No-Code (Actions) · Low-Code (C#) |
| **Automator** | DevOps and integration engineers who connect the engine to HR platforms, data pipelines, or custom applications | Client Services (.NET SDK)         |

> If you're a payroll domain expert who wants to define rules without writing application code, start with [No-Code & Low-Code Development ↗](https://payrollengine.org/docs/NoCodeLowCodeDevelopment).
> If you're a .NET developer integrating the engine into an existing system, start with [Client Services ↗](https://payrollengine.org/docs/ClientServices).

## How It Works

```
┌──────────────────────────────────────────────────────────┐
│                     Payroll Engine                        │
│                                                          │
│   Regulations          Payrun            Results         │
│  ┌────────────┐    ┌────────────┐    ┌────────────┐     │
│  │ Country    │    │            │    │ Payslips   │     │
│  │ Industry   │───▶│ Wage Types │───▶│ Reports    │     │
│  │ Company    │    │ Collectors │    │ Exports    │     │
│  └────────────┘    └────────────┘    └────────────┘     │
│        ▲                 ▲                               │
│        │                 │                               │
│   Regulation        Cases (Input)                        │
│   Layers            Time Data                            │
│                                                          │
│  REST API · Client SDK · Docker · Multi-Tenant           │
└──────────────────────────────────────────────────────────┘
```

**Regulation layers** define what to calculate — cases, wage types, collectors, reports, and lookups. Layers are stacked (base → country → industry → company) and objects from lower layers can be overridden.

**Cases** capture all wage-relevant data as time-stamped events with validity periods. This enables continuous payroll — run at any time, not just month-end — with unlimited cancel/undo and automatic retrospective calculations.

**Payrun** processes case data through the wage types and collectors defined in the regulation layers, producing payslips, reports, and data exports.

> 📖 Read more in the [Overview ↗](https://payrollengine.org/docs/Overview) or explore the [Payroll Model ↗](https://payrollengine.org/docs/PayrollModel).

## Prerequisites

| Requirement    | Version                                    |
|:--------------|:-------------------------------------------|
| **Docker**     | 20.10+ (for container-based setup)         |
| **SQL Server** | 2019+ or Azure SQL (for source builds)     |
| **.NET SDK**   | 8.0+ (for Client Services / source builds) |

## Quick Start

The Payroll Engine runs as a Docker container stack. [Docker](https://docs.docker.com/get-docker/) is the only prerequisite for the hosted setup.

**1. Login to the GitHub Container Registry:**

Create a GitHub [Personal Access Token](https://github.com/settings/tokens) with the `read:packages` scope, then login:

```sh
echo "<your-pat>" | docker login ghcr.io -u <github-username> --password-stdin
```

This is a one-time step per machine.

**2. Clone the repository and create the environment file:**

```sh
git clone https://github.com/Payroll-Engine/PayrollEngine.git
cd PayrollEngine
echo "DB_PASSWORD=PayrollStrongPass789" > .env
```

```powershell
# Windows (PowerShell)
git clone https://github.com/Payroll-Engine/PayrollEngine.git
Set-Location PayrollEngine
"DB_PASSWORD=PayrollStrongPass789" | Out-File .env -Encoding utf8
```

> Use alphanumeric characters only for the password — special characters can cause misleading authentication errors.

**3. Start the stack:**

```sh
docker compose -f docker-compose.ghcr.yml up -d
```

**4. Access the applications:**

| Service             | URL                   |
|--------------------|----------------------|
| **Web Application** | http://localhost:8081 |
| **Backend API**     | http://localhost:5001 |

The database is initialized automatically on first run. See [Container Setup ↗](https://payrollengine.org/docs/ContainerSetup) for the full configuration including version pinning and upgrades.

## Docker Images

Pre-built Linux images are published to the [GitHub Container Registry](https://github.com/orgs/Payroll-Engine/packages):

```sh
docker pull ghcr.io/payroll-engine/payrollengine.backend:latest
docker pull ghcr.io/payroll-engine/payrollengine.webapp:latest
docker pull ghcr.io/payroll-engine/payrollengine.payrollconsole:latest
```

Pin a specific version by replacing `:latest` with the release tag (e.g. `:2.1.0`).

## .NET Integration

Add the Client SDK to integrate the Payroll Engine into any .NET application:

```sh
dotnet add package PayrollEngine.Client.Services
```

Connect and query employees in a few lines:

```csharp
using PayrollEngine.Client.Services;

var httpClient = new HttpClient { BaseAddress = new Uri("http://localhost:5001") };
var tenantService = new TenantService(httpClient);

var tenants = await tenantService.QueryAsync();
foreach (var tenant in tenants)
    Console.WriteLine($"Tenant: {tenant.Identifier}");
```

All library packages are available on [NuGet.org](https://www.nuget.org/packages?q=PayrollEngine) and [GitHub Packages](https://github.com/orgs/Payroll-Engine/packages).

> See [Client Services ↗](https://payrollengine.org/docs/ClientServices) and [API Usage ↗](https://payrollengine.org/docs/ApiUsage) for full integration guides.

## Key Features

**Payroll Processing** — Regulation-based calculation with wage types and collectors. Multiple payruns per period, company divisions, forecasts, and instant payrun preview without side effects.

**Multi-Country & Multi-Industry** — Stackable regulation layers for any combination of country and industry rules. Multi-tenant with regulation sharing between companies.

**Time Data & Continuous Payroll** — Every data change is time-stamped with a validity period. Payroll runs are possible at any time. Past changes trigger automatic retrospective calculations; future changes apply when due.

**No-Code & Low-Code** — Case actions for data-entry control without writing code. C# scripting for custom business rules within an isolated, sandboxed scripting runtime.

**Test-Driven Development** — Automated testing of input (cases), processing (payrun), and output (reports). Test cases are defined alongside regulations and executed via Payroll Console or CI pipelines.

**Embedded & API-First** — REST API with Swagger/OpenAPI. .NET Client SDK. Docker containers for Backend, WebApp, and Console. OAuth 2.0 and API key authentication.

> 📖 Full feature list in the [Documentation ↗](https://payrollengine.org/docs).

## Repository Structure

This is the main repository containing setup files, examples, tests, and documentation. The source code is distributed across multiple repositories:

```
PayrollEngine/                  ← You are here
├── docker-compose.yml          Docker stack for local source builds
├── docker-compose.ghcr.yml     Docker stack using pre-built ghcr.io images
├── Setup/                      Setup and configuration files
├── Examples/                   Payroll examples (JSON/YAML)
├── Tests/                      Automated payroll tests
├── Schemas/                    JSON schemas for exchange format
├── Commands/                   Payroll Console command files
└── docs/                       API documentation, Swagger
```

### All Repositories

| Repository | Description | |
|:--|:--|:--|
| **PayrollEngine** | Main repo — setup, examples, tests, docs | [![release](https://img.shields.io/github/v/release/Payroll-Engine/PayrollEngine?include_prereleases&label=&logo=github)](https://github.com/Payroll-Engine/PayrollEngine/releases) |
| [Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend) | REST API server + SQL Server persistence | [![Docker](https://img.shields.io/badge/ghcr.io-image-blue?logo=docker)](https://github.com/orgs/Payroll-Engine/packages) |
| [WebApp](https://github.com/Payroll-Engine/PayrollEngine.WebApp) | Blazor web application | [![Docker](https://img.shields.io/badge/ghcr.io-image-blue?logo=docker)](https://github.com/orgs/Payroll-Engine/packages) |
| [PayrollConsole](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) | CLI for automation, testing, data import | [![Docker](https://img.shields.io/badge/ghcr.io-image-blue?logo=docker)](https://github.com/orgs/Payroll-Engine/packages) |
| [Client.Services](https://github.com/Payroll-Engine/PayrollEngine.Client.Services) | .NET Client SDK (NuGet entry package) | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Client.Services?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Client.Services) |
| [Client.Scripting](https://github.com/Payroll-Engine/PayrollEngine.Client.Scripting) | Scripting API for regulation development | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Client.Scripting?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Client.Scripting) |
| [Client.Core](https://github.com/Payroll-Engine/PayrollEngine.Client.Core) | Client core objects | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Client.Core?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Client.Core) |
| [Client.Test](https://github.com/Payroll-Engine/PayrollEngine.Client.Test) | Test runner library | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Client.Test?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Client.Test) |
| [Core](https://github.com/Payroll-Engine/PayrollEngine.Core) | Core payroll objects | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Core?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Core) |
| [Serilog](https://github.com/Payroll-Engine/PayrollEngine.Serilog) | Structured logging | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Serilog?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Serilog) |
| [Document](https://github.com/Payroll-Engine/PayrollEngine.Document) | Report generation | [![NuGet](https://img.shields.io/nuget/vpre/PayrollEngine.Document?label=&logo=nuget&color=blue)](https://www.nuget.org/packages/PayrollEngine.Document) |

> See [Repositories ↗](https://payrollengine.org/docs/Repositories) for the full map including third-party dependencies.

## Examples and Tests

Install all examples or run all tests using the [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole):

```sh
# Install all examples
docker run --rm --network payroll-engine_default \
  -e PayrollApiConnection="BaseUrl=http://backend-api:8080; Port=8080;" \
  ghcr.io/payroll-engine/payrollengine.payrollconsole:latest \
  PayrollImport --importFile Examples/Setup.all.pecmd

# Run all tests
docker run --rm --network payroll-engine_default \
  -e PayrollApiConnection="BaseUrl=http://backend-api:8080; Port=8080;" \
  ghcr.io/payroll-engine/payrollengine.payrollconsole:latest \
  PayrollTest --testFile Tests/Test.all.pecmd
```

| Examples                                    |                   | Tests                                         |                        |
|:-------------------------------------------|:-----------------|:---------------------------------------------|:-----------------------|
| [SimplePayroll](Examples/SimplePayroll)     | Minimal payroll   | [Payrun](Tests/Payrun.Test)                   | Core payrun test       |
| [ActionPayroll](Examples/ActionPayroll)     | Case actions      | [RetroPayroll](Tests/RetroPayroll.Test)       | Retrospective payrun   |
| [DerivedPayroll](Examples/DerivedPayroll)   | Regulation layers | [Calendar](Tests/Calendar.Test)               | Calendar types         |
| [ReportPayroll](Examples/ReportPayroll)     | Reporting         | [ForecastPayroll](Tests/ForecastPayroll.Test) | Forecast payrun        |
| [ExtendedPayroll](Examples/ExtendedPayroll) | Extended tutorial | [DerivedPayroll](Tests/DerivedPayroll.Test)   | Regulation inheritance |

> See [Resources ↗](https://payrollengine.org/docs/Resources) for the complete list of examples, tests, and client tutorials.

## Articles

| Article                                     |                                                                                                                                                                               |
|:-------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Payroll Software rethought                  | [payrollengine.org ↗](https://payrollengine.org/docs/PayrollSoftwareRethought)                                                                                                |
| Design of a scalable Payroll Software       | [payrollengine.org ↗](https://payrollengine.org/docs/DesignScalablePayrollSoftware)                                                                                           |
| Test Driven Payroll Software                | [payrollengine.org ↗](https://payrollengine.org/docs/TestDrivenPayrollSoftware)                                                                                               |
| No-Code and Low-Code for Payroll Software   | [payrollengine.org ↗](https://payrollengine.org/docs/NoCodeLowCodeDevelopment) · [dev.to](https://dev.to/giannoudis/no-code-and-low-code-for-payroll-software-development-1c35) |
| Travel through Time Data                    | [payrollengine.org ↗](https://payrollengine.org/docs/TravelThroughTimeData) · [dev.to](https://dev.to/giannoudis/travel-through-time-data-2op1)                               |
| High-performance backend scripting for .NET | [dev.to](https://dev.to/giannoudis/high-performance-backend-scripting-for-net-1jpg)                                                                                           |

## Contributing

Contributions are welcome — whether it's bug reports, regulation examples, documentation improvements, or feature discussions.

The project is approaching its **v1.0 release**. If you'd like to contribute, please read [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md) first. The best starting points are:

- 💬 [Discussions](https://github.com/Payroll-Engine/PayrollEngine/discussions) — questions, ideas, feedback
- 🐛 [Issues](https://github.com/Payroll-Engine/PayrollEngine/issues) — bug reports and feature requests
- 📖 Documentation and regulation examples are particularly welcome

## License

The Payroll Engine is licensed under the [MIT License](LICENSE). All third-party dependencies use MIT or Apache 2.0 licenses.
