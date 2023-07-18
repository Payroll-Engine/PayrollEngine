@echo off

rem verbose
set verbose=/verbose

rem test required database connection string
if "%PayrollEngineDatabase%" == "" goto configError

rem query tool
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

:modelSetup
call %query% Query SetupModel.sql "%PayrollEngineDatabase%" %verbose%
goto exit

:configError
echo.
echo [91mPayroll Engine database configuration is not available[0m
echo.
pause

:exit
set query=
set verbose=
