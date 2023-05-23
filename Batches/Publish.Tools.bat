@echo OFF
echo Payroll Engine Application Publisher
rem argument self contained, false=exclude runtime
SET PUB_SELF_CONTAINED=false
if not "%~1"=="" SET PUB_SELF_CONTAINED=%1
echo.
echo ----------------- Publishing JSON Schema Builder -----------------
dotnet publish %~dp0..\..\PayrollEngine.JsonSchemaBuilder\JsonSchemaBuilder\PayrollEngine.JsonSchemaBuilder.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\PayrollEngine.JsonSchemaBuilder --configuration Release
if %ERRORLEVEL% neq 0 goto error
echo.
echo ----------------- Publishing SQL Server Query -----------------
dotnet publish %~dp0..\..\PayrollEngine.SqlServer.DbQuery\DbQuery\PayrollEngine.SqlServer.DbQuery.csproj --self-contained %PUB_SELF_CONTAINED% --output %~dp0..\Bin\PayrollEngine.SqlServer.DbQuery --configuration Release
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
SET PUB_RUNTIME=
SET PUB_SELF_CONTAINED=
