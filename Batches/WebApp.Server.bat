@echo OFF
echo Starting Ason Payroll Web App...
pushd %~dp0..\..\PayrollEngine.WebApp\Server
start dotnet run PayrollEngine.WebApp.Server.csproj http --urls=http://localhost:44345/ --trust
popd
