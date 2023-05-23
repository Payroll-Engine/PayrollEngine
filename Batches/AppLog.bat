@echo off

REM --- arguments ---
if "%~1"=="" goto help
echo Payroll Engine %1 latest log

REM --- rem change to log folder ---
SET LogPath=%PROGRAMDATA%\PayrollEngine\%1\logs\
echo log path: %LogPath%
pushd %LogPath%

REM --- find the latest log file ---
for /f "tokens=*" %%a in ('dir *.log* /b /od') do set LastestLog=%%a
if "%LastestLog%"=="" goto error

REM --- open powershell ---
echo opening log file %LastestLog%
start powershell -NoExit -Command "$host.ui.RawUI.WindowTitle = '%1 - %LastestLog%'; Get-Content %LastestLog% -Tail 10 -wait"
goto exit

:error
echo Missing log file in folder %LogPath%
pause

:exit
popd
SET LogPath=
SET LastestLog=
