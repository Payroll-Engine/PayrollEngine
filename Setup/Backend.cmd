@echo off

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- parse backend server url ---
:backendServerUrl
call %query% ParseUrl backendServerUrl $BackendUrl$:$BackendPort$/
if %ERRORLEVEL% neq 0 goto setupError
if "%backendServerUrl%" == "" goto setupError

rem --- test backend connection ---
:testConnection
echo Testing backend server connection...
call %query% TestHttpConnection %backendServerUrl%
if %ERRORLEVEL% neq 0 goto connectionError

rem --- start swagger ---
:openWebBrowser
start "" %backendServerUrl%
echo.[92mBackend client started %backendServerUrl%[0m
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

rem --- cleanup ---
:exit
set query=
set backendServerUrl=
