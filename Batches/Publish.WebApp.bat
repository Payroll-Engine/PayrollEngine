@echo OFF
echo Payroll Engine Application Publisher
rem argument self contained, false=exclude runtime
SET PUB_SELF_CONTAINED=false
if not "%~1"=="" SET PUB_SELF_CONTAINED=%1
echo.
echo ----------------- Payroll WebApp -----------------
dotnet publish %~dp0..\..\PayrollEngine.WebApp\Server\PayrollEngine.WebApp.Server.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\PayrollEngine.WebApp --configuration Release
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
SET PUB_RUNTIME=
SET PUB_SELF_CONTAINED=
