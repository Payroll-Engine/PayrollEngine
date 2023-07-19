@echo off

rem --- setup configuration ---
set dbVersion=0.5.1

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test database ---
:testDatabaseConnection
echo Testing Payroll Engine Database...
call %query% TestSqlConnection
if %ERRORLEVEL% neq 0 goto connectionError

:testDatabaseVersion
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% neq 0 goto versionError

rem --- parse backend server url ---
:backendServerUrl
call %query% ParseUrl backendServerUrl $BackendUrl$:$BackendPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%backendServerUrl%" == "" goto setupError

rem --- test if the backend server connection is used ---
:testBackendConnection
echo Testing backend server connection...
rem delay for the errorlevel
timeout 2 > NUL
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% == 0 goto connectionError

rem --- start backend server ---
:startBackendServer
echo Starting Payroll Engine backend server...
pushd %~dp0PayrollEngine.Backend\
start /MIN "Payroll Engine - Backend Server" dotnet PayrollEngine.Backend.Server.dll --urls=%backendServerUrl%
popd
echo.[92mBackend server started %backendServerUrl%[0m
goto exit

rem --------------------------- error & exit ---------------------------

:setupError
echo.
echo.[91mPayroll Engine not installed[0m
echo.
pause
goto exit

:connectionError
echo.
echo.[91mPayroll Engine backend server %backendServerUrl% is not available[0m
echo.
pause
goto exit

:versionError
echo.
echo.[91mInvalid Payroll Engine backend database version[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set backendServerUrl=
set query=
set dbVersion=
