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

rem --- web application server doamin ---
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

rem --- start web application server ---
:startWebApp
pushd %~dp0PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppServerDomain%:%webAppServerPort%/
popd
goto exit

:backendError
echo.
echo [91mPayroll Engine Backend Server %backendUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set webAppServerDomain=
set webAppServerPort=
set backendUrl=
set backendDomain=
set backendPort=
set query=
