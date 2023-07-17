@echo off

rem --- backend domain ---
:backendDoamin
rem default backend domain
set backendDomain=https://localhost
rem environment override backend url
if not "%PayrollEnginebackendUrl%" == "" set backendDomain=%PayrollEnginebackendUrl%

rem --- backend port ---
:backendPort
rem default backend port
set backendPort=44354
rem environment override backend port
if not "%PayrollEnginebackendPort%" == "" set backendPort=%PayrollEnginebackendPort%

rem --- setup url ---
set backendUrl=%backendDomain%:%backendPort%/

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test backend connection ---
:testBackend
echo Testing backend connection %backendUrl%...
call %query% TestConnection %backendUrl%
if %ERRORLEVEL% neq 0 goto backendError

rem --- test backend data ---
:testBackendData
echo Testing backend data...
call %query% TestEmptyTable Tenant
if %ERRORLEVEL% neq 0 goto backendDataError

rem --- web application server domain ---
:webAppDomain
rem default web application server domain
set webAppServerDomain=https://localhost
rem environment override web application server url
if not "%PayrollEnginewebAppUrl%" == "" set webAppServerDomain=%PayrollEnginewebAppUrl%

rem --- web web application server port ---
:webAppPort
rem default web application server port
set webAppServerPort=7179
rem environment override web application server port
if not "%PayrollEnginewebAppPort%" == "" set webAppServerPort=%PayrollEnginewebAppPort%

set webAppUrl=%webAppServerDomain%:%webAppServerPort%/

rem --- test web application backend server ---
:testWebApp
echo Testing web application connection %backendUrl%...
call %query% TestConnection %webAppUrl%
if %ERRORLEVEL% == 0 goto connectionError

rem --- start web application server ---
:startWebApp
pushd %~dp0PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppUrl%
popd
goto exit

:connectionError
echo.
echo.[91mError connecting to %webAppUrl%[0m
echo.
pause
goto exit

:backendDataError
echo.
echo.[91mPayroll Engine backend server has no customer data[0m
echo.
pause
goto exit

:backendError
echo.
echo.[91mPayroll Engine backend server %backendUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set webAppServerDomain=
set webAppServerPort=
set webAppUrl=
set backendUrl=
set backendDomain=
set backendPort=
set query=
