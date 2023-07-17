@echo off

rem --- setup configuration ---
set dbVersion=1.0.0

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test database ---
:testDatabaseConnection
echo Testing Payroll Engine Database...
call %query% TestConnection
if %ERRORLEVEL% neq 0 goto connectionError

:testDatabaseVersion
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbVersion%
if %ERRORLEVEL% neq 0 goto versionError

rem --- backend server url ---
:backendServerUrl
rem default backend url
set backendServerUrl=https://localhost
rem environment override backend url
if not "%PayrollEngineBackendUrl%" == "" set backendServerUrl=%PayrollEngineBackendUrl%

rem --- backend server port ---
:backendServerPort
rem default backend port
set backendServerPort=44354
rem environment override backend port
if not "%PayrollEngineBackendPort%" == "" set backendServerPort=%PayrollEngineBackendPort%

rem --- start backend server ---
:startBackendServer
echo Starting Payroll Engine Backend Server...
pushd %~dp0PayrollEngine.Backend\
start dotnet PayrollEngine.Backend.Server.dll --urls=%backendServerUrl%:%backendServerPort%/
popd
goto exit

:connectionError
echo.
echo [91mPayroll Engine backend database is not available[0m
echo.
pause
goto exit

:versionError
echo.
echo [91mInvalid Payroll Engine backend database version[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set backendServerPort=
set backendServerUrl=
set query=
set dbVersion=
