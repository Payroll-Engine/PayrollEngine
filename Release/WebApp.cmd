@echo off

rem --- web app domain ---
:webAppDomain
rem default web application domain
set webAppDomain=https://localhost
rem environment override web application url
if not "%PayrollEnginewebAppUrl%" == "" set webAppDomain=%PayrollEnginewebAppUrl%

rem --- web app port ---
:webAppPort
rem default web application port
set webAppPort=7179
rem environment override web application port
if not "%PayrollEnginewebAppPort%" == "" set webAppPort=%PayrollEnginewebAppPort%

rem --- web application url ---
set webAppUrl=%webAppDomain%:%webAppPort%/

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test wab application connection ---
:testWebApp
echo Testing Web Application %webAppUrl%...
call %query% TestConnection %webAppUrl%
if %ERRORLEVEL% neq 0 goto webAppError

rem --- start web application ---
:openWebBrowser
start "" %webAppUrl%
goto exit

:webAppError
echo.
echo.[91mPayroll Engine Web Application %webAppUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set query=
set webAppUrl=
set webAppPort=
set webAppDomain=
