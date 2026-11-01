// Webhook receiver and test runner for the Webhook.Test integration tests (portable .NET, no scripts).
//
// Usage (from Tests/Webhook.Test):
//   dotnet run --project Receiver -- --run [all|unsigned|signed]   start the receiver, run pecmd, stop
//   dotnet run --project Receiver                                  receiver only (secret: env WEBHOOK_SECRET)
//
// The receiver listens on ASPNETCORE_URLS (default http://localhost:5099).
//
// Case function requests (POST /CaseFunctionRequest) answer the operations:
//   MinWage  -> 2000
//   Double   -> the request message (a number) multiplied by 2
//   Fail     -> HTTP 500
// All other webhook actions (POST /<ActionName>) are recorded and answered with 200.
//
// Signatures (secret set):
//   Requests must carry X-PE-Timestamp and X-PE-Signature = v1=hex(HMAC-SHA256(secret, "{timestamp}.{body}")),
//   otherwise the receiver answers 401. Function responses are signed with
//   X-PE-Response-Signature = v1=hex(HMAC-SHA256(secret, "{timestamp}.{requestSignature}.{responseBody}")).
//   The algorithm is implemented here independently of the backend on purpose.
//
// Diagnostics: GET /health, GET /received, DELETE /received
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

// must match the secret of Payroll.Signed.pt.json
const string SignedTestSecret = "webhook-test-secret";
const int MaxTimestampAgeSeconds = 300;
const string DefaultUrl = "http://localhost:5099";

var runIndex = Array.IndexOf(args, "--run");
var runMode = runIndex >= 0 && runIndex + 1 < args.Length ? args[runIndex + 1].ToLowerInvariant() : runIndex >= 0 ? "all" : null;

// the secret changes between the test runs
var secret = Environment.GetEnvironmentVariable("WEBHOOK_SECRET");
bool IsSigned() => !string.IsNullOrEmpty(secret);

var url = Environment.GetEnvironmentVariable("ASPNETCORE_URLS") ?? DefaultUrl;
var builder = WebApplication.CreateSlimBuilder(args.Where(a => a != "--run" && a != runMode).ToArray());
builder.WebHost.UseUrls(url);
if (runMode != null)
{
    builder.Logging.SetMinimumLevel(LogLevel.Warning);
}
var app = builder.Build();

var received = new ConcurrentQueue<ReceivedMessage>();

string Sign(string content) =>
    "v1=" + Convert.ToHexStringLower(HMACSHA256.HashData(Encoding.UTF8.GetBytes(secret), Encoding.UTF8.GetBytes(content)));

bool IsValid(string expected, string actual) =>
    actual != null && CryptographicOperations.FixedTimeEquals(Encoding.ASCII.GetBytes(expected), Encoding.ASCII.GetBytes(actual));

app.MapGet("/health", () => Results.Ok(IsSigned() ? "ok signed" : "ok"));
app.MapGet("/received", () => Results.Json(received.ToArray()));
app.MapDelete("/received", () =>
{
    received.Clear();
    return Results.NoContent();
});

app.MapPost("/{action}", async (string action, HttpRequest request) =>
{
    using var reader = new StreamReader(request.Body, Encoding.UTF8);
    var body = await reader.ReadToEndAsync();

    // signature check
    var signed = IsSigned();
    string timestampHeader = request.Headers["X-PE-Timestamp"];
    string requestSignature = request.Headers["X-PE-Signature"];
    var signatureValid = false;
    if (signed)
    {
        signatureValid = long.TryParse(timestampHeader, NumberStyles.None, CultureInfo.InvariantCulture, out var timestamp) &&
                         Math.Abs(DateTimeOffset.UtcNow.ToUnixTimeSeconds() - timestamp) <= MaxTimestampAgeSeconds &&
                         IsValid(Sign($"{timestampHeader}.{body}"), requestSignature);
    }

    string operation = null;
    string requestMessage = null;
    try
    {
        using var json = JsonDocument.Parse(body);
        if (json.RootElement.TryGetProperty("requestOperation", out var op))
        {
            operation = op.GetString();
        }
        if (json.RootElement.TryGetProperty("requestMessage", out var message))
        {
            requestMessage = message.GetString();
        }
    }
    catch (JsonException)
    {
        return Results.BadRequest("invalid json");
    }

    received.Enqueue(new(action, operation, requestMessage, signed, signatureValid, DateTime.UtcNow));

    if (signed && !signatureValid)
    {
        return Results.Unauthorized();
    }

    // function response with an optional response signature
    IResult Respond(string responseBody)
    {
        if (signed)
        {
            request.HttpContext.Response.Headers["X-PE-Response-Signature"] =
                Sign($"{timestampHeader}.{requestSignature}.{responseBody}");
        }
        return Results.Text(responseBody, "application/json");
    }

    if (!string.Equals(action, "CaseFunctionRequest", StringComparison.OrdinalIgnoreCase))
    {
        return Results.Ok();
    }

    switch (operation)
    {
        case "MinWage":
            return Respond("2000");
        case "Double":
            if (!decimal.TryParse(requestMessage, NumberStyles.Number, CultureInfo.InvariantCulture, out var value))
            {
                return Results.BadRequest("invalid number");
            }
            return Respond((value * 2).ToString(CultureInfo.InvariantCulture));
        case "Fail":
            return Results.StatusCode(500);
        default:
            return Respond(string.Empty);
    }
});

// receiver only
if (runMode == null)
{
    app.Run();
    return 0;
}

// test runner: receiver + pecmd, no platform specific scripts
if (runMode is not ("all" or "unsigned" or "signed"))
{
    Console.Error.WriteLine("Unknown run mode, use: all | unsigned | signed");
    return 2;
}

// the test directory is the folder with the pecmd files
var testDirectory = AppContext.BaseDirectory;
while (testDirectory != null && !File.Exists(Path.Combine(testDirectory, "Test.pecmd")))
{
    testDirectory = Path.GetDirectoryName(testDirectory.TrimEnd(Path.DirectorySeparatorChar));
}
if (testDirectory == null)
{
    Console.Error.WriteLine("Test.pecmd not found above " + AppContext.BaseDirectory);
    return 2;
}

int RunPecmd(string commandFile)
{
    var startInfo = new ProcessStartInfo("pecmd", commandFile)
    {
        WorkingDirectory = testDirectory,
        UseShellExecute = false
    };
    try
    {
        using var process = Process.Start(startInfo);
        process!.WaitForExit();
        return process.ExitCode;
    }
    catch (System.ComponentModel.Win32Exception exception)
    {
        Console.Error.WriteLine($"Cannot start pecmd (is it on the PATH?): {exception.Message}");
        return 2;
    }
}

var failed = 0;
await app.StartAsync();
try
{
    var phases = new List<(string Name, string Command, string Secret)>();
    if (runMode is "all" or "unsigned")
    {
        phases.Add(("Unsigned webhook", "Test.pecmd", null));
    }
    if (runMode is "all" or "signed")
    {
        phases.Add(("Signed webhook", "Test.Signed.pecmd", SignedTestSecret));
    }

    foreach (var (name, command, phaseSecret) in phases)
    {
        Console.WriteLine();
        Console.WriteLine($"=== {name} (receiver {url}) ===");
        secret = phaseSecret;
        received.Clear();

        var exitCode = RunPecmd(command);
        if (exitCode != 0)
        {
            failed++;
        }

        Console.WriteLine($"Received webhook messages: {received.Count}");
        foreach (var message in received)
        {
            Console.WriteLine($"  {message.Action} {message.Operation} signed={message.Signed} valid={message.SignatureValid}");
        }
    }
}
finally
{
    await app.StopAsync();
}

Console.WriteLine();
Console.WriteLine(failed == 0 ? "Webhook tests passed." : $"Webhook tests failed: {failed}");
return failed == 0 ? 0 : 1;

internal record ReceivedMessage(string Action, string Operation, string RequestMessage,
    bool Signed, bool SignatureValid, DateTime ReceivedUtc);
