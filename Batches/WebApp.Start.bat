@echo OFF
echo Starting Ason Payroll Web App...
pushd %~dp0..\..\PayrollEngine.WebApp\Client
start dotnet run PayrollEngine.WebApp.Client.csproj http --urls=http://localhost:44345/ --trust
popd
pause
