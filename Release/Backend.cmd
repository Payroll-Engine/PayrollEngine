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

rem --- start swagger ---
:openWebBrowser
start "" %backendUrl%
goto exit

:backendError
echo.
echo.[91mPayroll Engine Backend Server %backendUrl% is not available[0m
echo.
pause
goto exit

rem --- cleanup ---
:exit
set query=
set backendUrl=
set backendPort=
set backendDomain=
