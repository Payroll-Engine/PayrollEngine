@echo off

rem --- setup configuration ---
set dbMinVersion=1.0.0
set dbConnectionString=

rem --- setup system tools environment variables ---
echo Setup system tools...
call ConsoleSetup.cmd
call DbQuerySetup.cmd
echo.

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test available database server ---
:testDatabaseServer
echo Testing SQL Server...
call %query% TestServer %dbConnectionString%
if %ERRORLEVEL% neq 0 goto dbServerError
echo SQL Server available.

rem --- test available database ---
:testDatabase
echo Testing the database...
call %query% TestConnection %dbConnectionString%
if %ERRORLEVEL% neq 0 goto setupDatabase

rem --- test available database version ---
:testDatabaseVersion
echo Testing the database version %dbMinVersion%...
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbMinVersion%
if %ERRORLEVEL% neq 0 goto setupDatabase
echo Payroll Engine database is up to date.
goto startBackendServer

rem --- setup database ---
:setupDatabase
echo.
echo Setup Payroll Engine database...
call %query% Script Database\DatabaseVersion_%dbMinVersion%.sql
if %ERRORLEVEL% neq 0 goto dbSetupError

rem --- test database setup ---
:testDatabaseSetup
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbMinVersion%
if %ERRORLEVEL% neq 0 goto dbValidateError
echo Payroll Engine database setup completed.

rem --- start backend server ---
:startBackendServer
echo.
echo Starting Payroll Engine Backend Server...
call BackendServer.cmd

rem --- run backend tests ---
:runBackendTests
echo.
echo Backend Server Tests...
call Tests\Test.All.Payruns.cmd
if %ERRORLEVEL% neq 0 goto backendTestError

rem --- setup examples ---
:setupExamples
echo.
echo Setup Payroll Examples...
call Examples\Setup.All.cmd

rem --- start web application server ---
:startWebAppServer
echo.
echo Starting Web Application Server...
call WebAppServer.cmd

rem --- open web application ---
:openWebApp
echo.
echo Opening Web Application...
call WebApp.cmd

rem --- setup completed ---
:setupComplete
echo.
echo Setup completed.
echo.
echo Backend commands:
echo   BackendServer.cmd: start backend server
echo   Backend.cmd: open swagger UI
echo.
echo Web application commands:
echo   WebAppServer.cmd: start web appplication server
echo   WebApp.cmd: open web appplication
echo.
pause
goto exit

:dbServerError
echo Please install and start the SQL Server.
pause
goto exit

:dbSetupError
echo Error on SQL-Server setup.
pause
goto exit

:dbValidateError
echo SQL-Server setup failed.
pause
goto exit

:backendTestError
echo Payroll Test error.
pause
goto exit

:exit
set query=
set dbMinVersion=
