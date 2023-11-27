@echo off
setlocal enabledelayedexpansion

rem === public setup configuration - BEGIN ===
rem setup confirmation (default: true)
set confirmation=true
rem run of backend server (default: true)
set runBackendServer=true
rem open swagger (default: false)
set openSwagger=false
rem start web application server (default: true)
set runWebAppServer=true
rem open web application (default: true)
set openWebApp=true
rem execute backend server tests (default: true)
set executeTests=true
rem setup examples (default: true)
set setupExamples=true
rem === public setup configuration - END ===

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
echo   - run backend server [96m%runBackendServer%[0m
echo   - open swagger [96m%openSwagger%[0m
echo   - run web application server [96m%runWebAppServer%[0m
echo   - open web application [96m%openWebApp%[0m
echo   - execute backend tests [96m%executeTests%[0m
echo   - setup payroll examples [96m%setupExamples%[0m
echo.
echo Database version [96m%dbVersion%[0m
echo.
if "%confirmation%" == "false" goto setupConfiguration
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to continue..."
echo.
echo.

rem --- test .NET 8.0 runtime ---
:testDotNet
set tempFile=%TEMP%\Output.log
dotnet --list-runtimes|FIND "8." > "!tempFile!"
if %ErrorLevel% neq 0 goto dotNetError

rem --- setup environment ---
:setupConfiguration
set PayrollConfiguration=%~dp0engine.json
rem --- future processes ---
setx PayrollConfiguration "%~dp0engine.json" > nul

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
echo Testing database...
call %query% TestSqlConnection
if %ERRORLEVEL% neq 0 goto setupDatabase

rem --- test available database version ---
:testDatabaseVersion
echo Testing database version %dbVersion%...
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% == 0 goto runBackendServerServer

rem --- setup database ---
:setupDatabase
echo Setup database...
call %query% Query Database\SetupDefaultDatabase.sql /noCatalog
if %ERRORLEVEL% neq 0 goto dbSetupError

rem --- setup database model ---
:setupDatabaseModel
echo Setup database model...
call %query% Query Database\SetupModel.sql
if %ERRORLEVEL% neq 0 goto dbSetupErrorModel

rem --- test database setup ---
:testDatabaseSetup
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% neq 0 goto dbValidateError
echo.[92mDatabase setup completed[0m

rem --- parse backend server url ---
:backendServerUrl
call %query% ParseUrl backendServerUrl $BackendUrl$:$BackendPort$/
rem delay for the errorlevel
timeout 2 > NUL
if %ERRORLEVEL% neq 0 goto setupError
if "%backendServerUrl%" == "" goto setupError

rem --- test if the backend server is already running ---
:testBackendRunning
echo Testing backend server is running...
rem delay for the errorlevel
timeout 2 > NUL
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% == 0 goto executeBackendServerTests

rem --- run backend server ---
:runBackendServerServer
if "%runBackendServer%" == "false" goto setupComplete
echo Starting backend server...
pushd %~dp0PayrollEngine.Backend\
start /MIN "Payroll Engine - Backend Server" dotnet PayrollEngine.Backend.Server.dll --urls=%backendServerUrl%
echo.[96mBackend server started %backendServerUrl%[0m
popd

rem --- test if the backend server has been started ---
:testBackendStarted
echo Testing backend server start...
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% neq 0 goto backendStartError

rem --- execute backend server tests ---
:executeBackendServerTests
if "%executeTests%" == "false" goto openSwagger
echo Executing tests...
pushd %~dp0Tests\
call Test.All.cmd
popd

rem --- open swagger ---
:openSwagger
if "%openSwagger%" == "false" goto setupExamples
start "" %backendServerUrl%
echo.[96mBackend client started %backendServerUrl%[0m
goto exit

rem --- setup example ---
:setupExamples
if "%setupExamples%" == "false" goto runWebAppServer
echo Setup examples...
rem ensure required tenant for the  web application
pushd %~dp0Examples\StartPayroll\
call Setup.cmd /nowait
popd

rem --- run web application server ---
:runWebAppServer
if "%runWebAppServer%" == "false" goto setupComplete
echo Starting web application server...

rem --- parse web application server url ---
:webAppServerUrl
call %query% ParseUrl webAppServerUrl $WebAppUrl$:$WebAppPort$/
rem delay for the errorlevel
timeout 2 > NUL
if %ERRORLEVEL% neq 0 goto setupError
if "%webAppServerUrl%" == "" goto setupError

rem --- test if the web application server connection is used ---
:testWebApp
rem delay for the errorlevel
timeout 2 > NUL
echo Testing web application server %webAppServerUrl%...
call %query% TestHttpConnection %webAppServerUrl%
if %ERRORLEVEL% == 0 goto openWebApp

rem --- start web application server ---
:startTestedWebAppServer
pushd %~dp0PayrollEngine.WebApp\
start /MIN "Payroll Engine - Web Application Server" dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppServerUrl%
echo.[96mWeb application server started %webAppServerUrl%[0m
popd

rem --- open web application ---
:openWebApp
if "%openWebApp%" == "false" goto setupComplete
echo Starting web application ...
start "" %webAppServerUrl%
echo.[96mWeb application started[0m

rem --- setup completed ---
:setupComplete
echo.
echo.[92mSetup completed[0m
if not "%runBackendServer%" == "false" echo.  - backend server is running
if not "%openSwagger%" == "false" echo.  - swagger opened
if not "%runWebAppServer%" == "false" echo.  - web application server is running
if not "%openWebApp%" == "false" echo.  - web application opened
if not "%executeTests%" == "false" echo.  - backend tests executed
if not "%setupExamples%" == "false" echo.  - payroll examples installed
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
echo   folder [96mdoc[0m: documentation
echo   folder [96mSchema[0m: JSON validation schemas
echo.
pause>nul|set/p ="Press any key to close this window..."
goto exit

rem --------------------------- error & exit ---------------------------

:setupError
echo.
echo.[91mPayroll Engine not installed[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:backendStartError
echo.
echo.[91mPayroll Engine backend server can not be started %backendServerUrl%[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dbServerError
echo.[91mPlease install and start the SQL Server[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dbClearError
echo.[91mError on SQL-Server clear[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dbSetupError
echo.[91mError on SQL-Server setup[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dbSetupErrorModel
echo.[91mError on SQL-Server model setup[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dbValidateError
echo.[91mSQL-Server setup version validation failed %dbVersion%[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:backendTestError
echo.[91mPayroll test error[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

:dotNetError
echo.[91m.NET 8.0 Runtime is missing[0m
echo.
echo Please download and install the runtime for ASP.NET Core server applications
echo   - https://dotnet.microsoft.com/en-us/download/dotnet/8.0/runtime
echo     Windows: Run server apps - Download Hosting Bundle
echo     Linux:   Run server apps - Install .NET
echo.
pause
goto exit

:exit
set webAppServerUrl=
set backendServerUrl=
set query=
set tempFile=
rem config
set confirmation=
set runBackendServer=
set openSwagger=
set runWebAppServer=
set openWebApp=
set executeTests=
set setupExamples=
set dbVersion=
