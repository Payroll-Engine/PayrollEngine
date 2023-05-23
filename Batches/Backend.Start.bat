@echo OFF
echo Starting Payroll Engine Backend Server...
cd %~dp0..\Bin\PayrollEngine.Backend\
start dotnet PayrollEngine.Backend.Server.dll --urls=https://localhost:44354/
