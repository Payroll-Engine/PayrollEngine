@echo off

rem --- public setup configuration ---
rem disable the setup confirmation
set confirmation=true
rem disable start of the backend server (and dependend items)
set startBackend=true
rem disable start of the web application server
set startWebApp=true
rem disable backend server tests
set tests=true
rem disable examples setup
set examples=true

rem --- internal setup configuration (do not change)---
set dbVersion=0.5.1

rem --- title ---
:title
echo.[7m --- Payroll Engine Setup --- [0m
echo.

rem --- confirmation ---
:confirmation
echo [97mSetup settings[0m
echo   - confirmation [96m%confirmation%[0m
echo   - start backend [96m%startBackend%[0m
echo   - start web application [96m%startWebApp%[0m
echo   - run tests [96m%tests%[0m
echo   - setup examples [96m%examples%[0m
echo.
echo   - database version [96m%dbVersion%[0m
echo.
if "%confirmation%" == "false" goto setupTools
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to continue..."
echo.
echo.

rem --- setup environment ---
:setupConfiguration
set PayrollConfiguration=%~dp0config.json
rem --- future processes ---
setx PayrollConfiguration "%~dp0config.json" > nul

rem --- setup payroll console ---
:setupPayrollConsole
set PayrollConsole=%~dp0PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe
rem --- future processes ---
setx PayrollConsole "%~dp0PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe" > nul

rem --- setup db query ---
:setupDbQuery
set PayrollDbQuery=%~dp0PayrollEngine.SqlServer.DbQuery\PayrollEngine.SqlServer.DbQuery.exe
rem --- future processes ---
setx PayrollDbQuery "%~dp0PayrollEngine.SqlServer.DbQuery\PayrollEngine.SqlServer.DbQuery.exe" > nul
set query=%PayrollDbQuery%

rem --- test available database server ---
:testDatabaseServer
echo Testing SQL Server...
call %query% TestServer /noCatalog
if %ERRORLEVEL% neq 0 goto dbServerError
echo SQL Server available.

rem --- test available database ---
:testDatabase
echo Testing the database...
call %query% TestSqlConnection
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

rem --- parse backend server url ---
:backendServerUrl
call %query% ParseUrl backendServerUrl $BackendUrl$:$BackendPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%backendServerUrl%" == "" goto setupError

rem --- test if the backend server is already running ---
:testBackendRunning
echo Testing backend server is running...
rem delay for the errorlevel
timeout 2 > NUL
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% == 0 goto startBackendTests

rem --- start backend server ---
:startBackendServer
if "%startBackend%" == "false" goto setupComplete
echo Starting Payroll Engine backend server...
pushd %~dp0PayrollEngine.Backend\
start /MIN "Payroll Engine - Backend Server" dotnet PayrollEngine.Backend.Server.dll --urls=%backendServerUrl%
popd

rem --- test if the backend server has been started ---
:testBackendStarted
echo Testing backend server start...
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% neq 0 goto backendStartError

rem --- start backend server tests ---
:startBackendTests
if "%tests%" == "false" goto setupExamples
echo Executing tests...
pushd %~dp0Tests\
call Test.All.cmd
popd

rem --- setup example ---
:setupExamples
if "%examples%" == "false" goto startWebAppServer
echo Setup examples...
rem ensure required tenant for the  web application
pushd %~dp0Examples\StartPayroll\
call Setup.cmd /nowait
popd

rem --- start web application server ---
:startWebAppServer
if "%startWebApp%" == "false" goto setupComplete
echo Starting Payroll Engine Web Application Server...

rem --- parse web application server url ---
:webAppServerUrl
call %query% ParseUrl webAppServerUrl $WebAppUrl$:$WebAppPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%webAppServerUrl%" == "" goto setupError

rem --- test if the web application server connection is used ---
:testWebApp
echo Testing web application server %webAppServerUrl%...
call %query% TestHttpConnection %webAppServerUrl%
if %ERRORLEVEL% == 0 goto setupComplete

rem --- start web application server ---
:startWebApp
pushd %~dp0PayrollEngine.WebApp\
start /MIN "Payroll Engine - Web Application Server" dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppServerUrl%
popd

rem --- setup completed ---
:setupComplete
echo.
echo.[92mSetup completed[0m
if not "%startBackend%" == "false" echo.  - backend server started
if not "%tests%" == "false" echo.  - tests executed
if not "%examples%" == "false" echo.  - examples installed
if not "%startWebApp%" == "false" echo.  - web application server started
echo.
echo [97mBackend commands[0m
echo   [96mBackendServer.cmd[0m [BS]: start backend server
echo   [96mBackend.cmd[0m: open swagger UI [requires BS]
echo.
echo [97mWeb application commands[0m
echo   [96mWebAppServer.cmd[0m [WS]: start web application server [BS]
echo   [96mWebApp.cmd[0m: open web application [BS, WS]
echo.
echo [97mMore[0m
echo   [96mTests\Test.All.cmd[0m: run all payrun tests [BS]
echo   [96mExamples\Setup.All.cmd[0m: setup all payroll examples [BS]
echo   [96mdoc[0m folder: documentation
echo   [96mSchema[0m folder: JSON validation schemas
echo.
pause>nul|set/p ="Press any key to close this window..."
goto exit

rem --------------------------- error & exit ---------------------------

:setupError
echo.
echo.[91mPayroll Engine not installed[0m
echo.
pause
goto exit

:backendStartError
echo.
echo.[91mPayroll Engine backend server can not be started %backendServerUrl%[0m
echo.
pause
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
echo.[91mSQL-Server setup version validation failed %dbVersion%[0m
pause
goto exit

:backendTestError
echo.[91mPayroll Test error[0m
pause
goto exit

:exit
set webAppServerUrl=
set backendServerUrl=
set query=
set tests=
set exmaple=
set dbVersion=
set confirmation=
set startBackend=
set startWebApp=
