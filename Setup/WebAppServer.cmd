@echo off

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- parse backend server url ---
:backendServerUrl
call %query% ParseUrl backendServerUrl $BackendUrl$:$BackendPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%backendServerUrl%" == "" goto setupError

rem --- test backend server connection ---
:testBackendConnection
echo Testing backend server connection...
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% neq 0 goto backendConnectionError

rem --- test backend server data (test for tenants) ---
:testBackendData
echo Testing backend server data...
call %query% TestEmptyTable Tenant
if %ERRORLEVEL% neq 0 goto backendDataError

rem --- parse web application server url ---
:webAppServerUrl
call %query% ParseUrl webAppServerUrl $WebAppUrl$:$WebAppPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%webAppServerUrl%" == "" goto setupError

rem --- test if the web application server connection is used ---
:testWebApp
echo Testing web application server %webAppServerUrl%...
rem delay for the errorlevel
timeout 2 > NUL
call %query% TestHttpConnection %webAppServerUrl%
if %ERRORLEVEL% == 0 goto webAppConnectionError

rem --- start web application server ---
:startWebApp
pushd %~dp0PayrollEngine.WebApp\
start /MIN "Payroll Engine - Web Application Server" dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppServerUrl%
popd
echo.[92mWeb application server started %webAppServerUrl%[0m
goto exit

rem --------------------------- error & exit ---------------------------

:setupError
echo.
echo.[91mPayroll Engine backend not installed[0m
echo.
pause
goto exit

:webAppConnectionError
echo.
echo.[91mError connecting to %webAppServerUrl%[0m
echo.
pause
goto exit

:backendDataError
echo.
echo.[91mPayroll Engine backend server has no data[0m
echo.
pause
goto exit

:backendConnectionError
echo.
echo.[91mPayroll Engine backend server %backendServerUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set webAppServerUrl=
set backendServerUrl=
set query=
