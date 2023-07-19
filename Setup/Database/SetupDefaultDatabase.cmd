@echo off

rem verbose
set verbose=/verbose

rem test required database connection string
if "%PayrollEngineDatabase%" == "" goto configError

rem query tool
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

:dbSetup
call %query% Query SetupDefaultDatabase.sql "%PayrollEngineDatabase%" %verbose% /noCatalog
goto exit

:configError
echo.
echo [91mPayroll Engine database configuration is not available[0m
echo.
pause

:exit
set query=
set verbose=
