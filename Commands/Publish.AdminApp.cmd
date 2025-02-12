@echo OFF
echo Payroll Engine Application Publisher
rem argument self contained, false=exclude runtime
SET PUB_SELF_CONTAINED=false
if not "%~1"=="" SET PUB_SELF_CONTAINED=%1
echo.
echo ----------------- Payroll AdminApp -----------------
echo.
echo Cleanup...
if exist ..\Bin\Admin\ RD /Q /S ..\Bin\Admin\ > NUL
if %ERRORLEVEL% neq 0 goto error
echo.
dotnet publish %~dp0..\..\PayrollEngine.AdminApp\Windows\PayrollEngine.AdminApp.Windows.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\Admin --configuration Release
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
SET PUB_RUNTIME=
SET PUB_SELF_CONTAINED=
