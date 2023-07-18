@echo off

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- parse web application server url ---
:webAppServerUrl
call %query% ParseUrl webAppServerUrl $WebAppUrl$:$WebAppPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%webAppServerUrl%" == "" goto setupError

rem --- test wab application server connection ---
:testWebApp
echo Testing web application server %webAppServerUrl%...
call %query% TestHttpConnection %webAppServerUrl%
if %ERRORLEVEL% neq 0 goto connectionError

rem --- start web application ---
:openWebBrowser
start "" %webAppServerUrl%
echo.[92mWeb application started %webAppServerUrl%[0m
goto exit

rem --------------------------- error & exit ---------------------------

:setupError
echo.
echo.[91mPayroll Engine backend not installed[0m
echo.
pause
goto exit

:connectionError
echo.
echo.[91mPayroll Engine web application server %webAppServerUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set query=
set webAppServerUrl=
