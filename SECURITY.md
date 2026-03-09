# Security Policy

## Supported Versions

The Payroll Engine is currently in pre-release. Security fixes are applied to
the latest release only.

| Version      | Supported          |
|:-------------|:-------------------|
| 0.9.x-beta   | ✅ Latest release  |
| < 0.9.0      | ❌ Not supported   |

Once version 1.0 is released, a long-term support policy will be defined.

## Reporting a Vulnerability

> ⚠️ **Please do not report security vulnerabilities through public GitHub issues.**

To report a security vulnerability, send an e-mail to:

**info@payrollengine.org**

Please include as much of the following information as possible to help us
understand and reproduce the issue:

- Type of vulnerability (e.g. authentication bypass, SQL injection, XSS)
- Affected component (Backend, Web Application, Console, API)
- Steps to reproduce
- Potential impact
- Any suggested mitigation (optional)

## Response Timeline

| Step              | Target timeframe    |
|:------------------|:--------------------|
| Initial response  | Within 48 hours     |
| Assessment        | Within 7 days       |
| Fix or workaround | Depends on severity |

We will keep you informed of the progress throughout the process. We ask that
you give us a reasonable time to address the issue before any public disclosure.

## Scope

This policy covers the following repositories:

- [PayrollEngine](https://github.com/Payroll-Engine/PayrollEngine) — Setup, examples and tests
- [PayrollEngine.Backend](https://github.com/Payroll-Engine/PayrollEngine.Backend) — Backend API server
- [PayrollEngine.WebApp](https://github.com/Payroll-Engine/PayrollEngine.WebApp) — Web application
- [PayrollEngine.PayrollConsole](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) — Console client

## Deployment Note

The Payroll Engine is a backend service designed for use within **protected
network environments**. It is **not intended for direct exposure to the public
Internet**. For available security configuration options (authentication, rate
limiting, CORS, script safety analysis), refer to the
[Security documentation](https://github.com/Payroll-Engine/PayrollEngine/wiki/Security).
