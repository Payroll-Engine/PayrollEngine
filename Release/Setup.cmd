@echo off

rem --- setup configuration ---
set confirmation=true
set startBackend=true
set startWebApp=false
rem do not change the db version
set dbVersion=1.0.0

rem --- title ---
:title
echo.[7m --- Payroll Engine Setup v%dbVersion% --- [0m
echo.

rem --- setup confirmation ---
:confirmation
if "%confirmation%" == "false" goto setupTools
pause>nul|set/p ="Press <Ctrl+C> to exit the setup or <Enter> to continue..."
echo.
echo.

rem --- setup system environment and tools ---
:setupTools
echo Setup system environment and tools...
call Setup\EnvironmentSetup.cmd
call Setup\ConsoleSetup.cmd
call Setup\DbQuerySetup.cmd

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test available database server ---
:testDatabaseServer
echo Testing SQL Server...
call %query% TestServer /noCatalog
if %ERRORLEVEL% neq 0 goto dbServerError
echo SQL Server available.

rem --- test available database ---
:testDatabase
echo Testing the database...
call %query% TestConnection
if %ERRORLEVEL% neq 0 goto setupDatabase

rem --- test available database version ---
:testDatabaseVersion
echo Testing the database version %dbVersion%...
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% == 0 goto startBackendServer

rem --- setup database ---
:setupDatabase
echo Setup Payroll Engine database...
call %query% Query Database\SetupDefaultDatabase.sql /noCatalog
if %ERRORLEVEL% neq 0 goto dbSetupError

rem --- setup database model ---
:setupDatabaseModel
echo Setup Payroll Engine database model...
call %query% Query Database\SetupModel.sql
if %ERRORLEVEL% neq 0 goto dbSetupErrorModel

rem --- test database setup ---
:testDatabaseSetup
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% neq 0 goto dbValidateError
echo.[92mPayroll Engine database setup completed[0m

rem --- start backend server ---
:startBackendServer
if "%startBackend%" == "false" goto setupComplete
echo Starting Payroll Engine Backend Server...
call BackendServer.cmd

rem --- start web application server ---
:startWebAppServer
if "%startWebApp%" == "false" goto setupComplete
echo Starting Payroll Engine Web Application Server...
call WebAppServer.cmd

rem --- setup completed ---
:setupComplete
echo.
echo.[92mSetup completed and backend server started[0m
echo.
echo [97mBackend commands[0m
echo   [96mBackendServer.cmd[0m [BS]: start backend server
echo   [96mBackend.cmd[0m: open swagger UI [requires BS]
echo.
echo [97mWeb application commands[0m
echo   [96mWebAppServer.cmd[0m [WA]: start web application server [BS]
echo   [96mWebApp.cmd[0m: open web application [BS, WA]
echo.
echo [97mMore[0m
echo   [96mTests\Test.All.cmd[0m: run all payrun tests [BS]
echo   [96mExamples\Setup.All.cmd[0m: setup all payroll examples [BS]
echo   [96mdoc[0m folder: documentation
echo   [96mSchema[0m folder: JSON validation schemas
echo.
pause>nul|set/p ="Press any key to close this window..."
goto exit

:dbServerError
echo.[91mPlease install and start the SQL Server[0m
pause
goto exit

:dbClearError
echo.[91mError on SQL-Server clear[0m
pause
goto exit

:dbSetupError
echo.[91mError on SQL-Server setup[0m
pause
goto exit

:dbSetupErrorModel
echo.[91mError on SQL-Server model setup[0m
pause
goto exit

:dbValidateError
echo.[91mSQL-Server setup failed[0m
pause
goto exit

:backendTestError
echo.[91mPayroll Test error[0m
pause
goto exit

:exit
set query=
set dbVersion=
set confirmation=
set startBackend=
set startWebApp=
