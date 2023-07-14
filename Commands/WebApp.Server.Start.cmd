@echo OFF
echo Starting Payroll Engine Web App...
pushd %~dp0..\Bin\PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=https://localhost:7179/
popd
