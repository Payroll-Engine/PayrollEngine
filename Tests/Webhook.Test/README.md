# Webhook.Test

Integration tests for **synchronous (scripting) webhooks**: a wage type script calls
`InvokeWebhook<T>()`, the backend posts a `CaseFunctionRequest` to an external receiver and the
response becomes the wage type value.

| Test | Tenant | Payroll file | Command |
|:--|:--|:--|:--|
| Unsigned webhook | `Webhook.Test` | `Payroll.pt.json` | `Test.pecmd` |
| Signed webhook (HMAC) | `Webhook.Signed.Test` | `Payroll.Signed.pt.json` | `Test.Signed.pecmd` |

Unlike the other tests these need an external process, the **webhook receiver**
(`Receiver/`, a minimal ASP.NET Core app). Therefore they are **not part of `Test.All.pecmd`**.

---

## Scenario

**Division:** `WebhookDivision` (de-CH)  
**Employee:** `maja.berger@webhook.test` (signed: `maja.berger@webhook.signed.test`)  
**Webhook:** `CaseFunctionRequest` -> `http://localhost:5099/CaseFunctionRequest`

| WT | Script | Receiver answer | Expected |
|--:|:--|:--|--:|
| 101 | `InvokeWebhook<decimal>("MinWage")` | `2000` | 2 000 |
| 102 | `InvokeWebhook<decimal>("Double", 750M)` | request message x 2 | 1 500 |
| 103 | `WageType[101] + WageType[102]` | - | 3 500 |

### Receiver operations

| Operation | Answer |
|:--|:--|
| `MinWage` | `2000` |
| `Double` | the numeric request message multiplied by 2 |
| `Fail` | HTTP 500 |

Other webhook actions (`POST /<ActionName>`) are recorded and answered with `200`.
`GET /received` lists all received messages (including `signed` / `signatureValid`),
`DELETE /received` clears them.

---

## Signed webhook

The webhook of the signed test has a `secret` (`webhook-test-secret`). The backend then sends

| Header | Value |
|:--|:--|
| `X-PE-Timestamp` | unix time in seconds |
| `X-PE-Signature` | `v1=` + hex HMAC-SHA256 of `{timestamp}.{body}` |

and requires the response of a function request to carry

| Header | Value |
|:--|:--|
| `X-PE-Response-Signature` | `v1=` + hex HMAC-SHA256 of `{timestamp}.{requestSignature}.{responseBody}` |

The receiver (started with the environment variable `WEBHOOK_SECRET`) verifies the request with its
**own implementation** of the algorithm (answers `401` for an invalid or missing signature or a
timestamp older than 5 minutes) and signs its responses. The payrun only completes with the expected
wage type values, if both directions are valid: a wrong request signature makes the receiver answer
`401` (no value), a wrong response signature makes the backend fail the function.

---

## Running the Tests

The backend must be running (schema v1.2.0 with the `Webhook.Secret` column), `pecmd` must be on the
`PATH` and the backend must be able to reach the receiver address. No platform specific script is
needed: the receiver is also the test runner (plain .NET, runs on Windows, Linux and macOS).

```
cd Tests/Webhook.Test
dotnet run --project Receiver -- --run            # both tests
dotnet run --project Receiver -- --run signed     # only the signed test (or: unsigned)
```

The runner starts the receiver, runs `pecmd Test.pecmd` (no secret) and `pecmd Test.Signed.pecmd`
(secret `webhook-test-secret`), prints the received messages and stops. The exit code is the number
of failed tests. `dotnet run --project Receiver` without `--run` starts only the receiver (secret from
the environment variable `WEBHOOK_SECRET`), e.g. to run `pecmd` manually.

On Windows there are shortcuts: `Receiver.cmd` starts the receiver without a secret (unsigned test),
`Receiver.signed.cmd` with the secret of the signed test, `Receiver.cmd --run [mode]` runs the tests.
Check `http://localhost:5099/health`: `ok` = without secret, `ok signed` = with secret.

When the backend runs in a container, `localhost` is not the host: change `receiverAddress` in the
payroll files and set `ASPNETCORE_URLS` to an address the container can reach.
> Webhook secrets are stored encrypted (ASP.NET Core data protection). Set
> `PayrollServerConfiguration:DataProtectionKeyPath` to a persistent directory, otherwise the keys
> are lost with the container and the stored secrets cannot be read anymore.
