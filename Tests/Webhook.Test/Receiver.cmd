@echo off
rem Starts the webhook receiver (Ctrl+C to stop).
rem   Receiver.cmd                  receiver without secret (unsigned test)
rem   Receiver.cmd signed           receiver with the secret of the signed test
rem   Receiver.cmd --run [mode]     receiver and test runner: all ^| unsigned ^| signed
rem The receiver listens on ASPNETCORE_URLS (default http://localhost:5099).
setlocal
cd /d "%~dp0"

if /i "%~1"=="signed" (
    set WEBHOOK_SECRET=webhook-test-secret
    shift
)

dotnet run --project Receiver -- %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b %ERRORLEVEL%
