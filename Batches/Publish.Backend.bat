@echo OFF
echo Payroll Engine Backend Publisher
rem argument self contained, false=exclude runtime
SET PUB_SELF_CONTAINED=false
if not "%~1"=="" SET PUB_SELF_CONTAINED=%1
echo.
echo ----------------- Payroll Engine Backend -----------------
dotnet publish %~dp0..\..\PayrollEngine.Backend\Backend.Server\PayrollEngine.Backend.Server.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\PayrollEngine.Backend --configuration Release
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
SET PUB_RUNTIME=
SET PUB_SELF_CONTAINED=
