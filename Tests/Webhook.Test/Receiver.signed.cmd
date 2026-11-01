@echo off
rem Starts the webhook receiver with the secret of the signed test (Ctrl+C to stop).
rem The secret must match Payroll.Signed.pt.json. Listens on ASPNETCORE_URLS (default http://localhost:5099).
setlocal
cd /d "%~dp0"
set WEBHOOK_SECRET=webhook-test-secret
dotnet run --project Receiver
exit /b %ERRORLEVEL%
