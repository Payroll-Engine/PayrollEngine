@echo off

rem web app port
set webappport=7179

echo Starting Payroll Engine Web App...
pushd %~dp0PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=https://localhost:%webappport%/
popd

set webappport=
