@echo OFF
echo Payroll Engine Application Publisher
rem argument self contained, false=exclude runtime
SET PUB_SELF_CONTAINED=false
if not "%~1"=="" SET PUB_SELF_CONTAINED=%1
echo.
echo ----------------- Payroll Console -----------------
dotnet publish %~dp0..\..\PayrollEngine.PayrollConsole\PayrollConsole\PayrollEngine.PayrollConsole.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\PayrollEngine.PayrollConsole --configuration Release
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
SET PUB_RUNTIME=
SET PUB_SELF_CONTAINED=
