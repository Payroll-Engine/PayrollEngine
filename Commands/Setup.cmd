@echo off
rem Use "Setup nopub" to skip binary publish

rem --- setup version ---
set version=0.5.0-230719-4

rem --- setup file ---
set setup=%~dp0..\Bin\PayrollEngine_%version%.zip
rem existing setup test
if exist %setup% goto existingVersionError

echo.
echo Payroll Engine Setup
echo.
echo target: %version%
echo.

rem --- compress only switch ---
set publish=true
if "%1" == "nopub" goto compressSetup

rem --- publish exes and nugets ---
:publishBinaries
echo.
echo publishing system tools...
call Publish.Tools.cmd
echo building nugets...
call Pack.All.cmd %1
echo publishing backend...
call Publish.Backend.cmd
echo publishing payroll console...
call Publish.PayrollConsole.cmd
echo publishing web application...
call Publish.WebApp.cmd

rem --- compress ---
:compressSetup
echo.
echo ------------------- Setup archive -------------------
echo.
rem setup files
echo compressing setup files...
7z a -ssw -r -tzip -y %setup% %~dp0..\Setup\*.* > nul
rem db query tool
echo compressing db query tool...
7z a -ssw -r -tzip -y %setup% %~dp0..\Bin\PayrollEngine.SqlServer.DbQuery > nul
rem payroll backend
echo compressing payroll backend...
7z a -ssw -r -tzip -y %setup% %~dp0..\Bin\PayrollEngine.Backend > nul
rem payroll console
echo compressing payroll console...
7z a -ssw -r -tzip -y %setup% %~dp0..\Bin\PayrollEngine.PayrollConsole > nul
rem web application
echo compressing web application...
7z a -ssw -r -tzip -y %setup% %~dp0..\Bin\PayrollEngine.WebApp > nul
rem schemas
echo compressing schemas...
7z a -ssw -r -tzip -y %setup% %~dp0..\Schemas > nul
rem tests
echo compressing tests...
7z a -ssw -r -tzip -y %setup% %~dp0..\Tests > nul
rem examples
echo compressing examples...
7z a -ssw -r -tzip -y %setup% %~dp0..\Examples > nul
rem documents
echo compressing documents...
7z a -ssw -r -tzip -y %setup% %~dp0..\docs > nul

echo.
echo.[92mSetup completed %setup%[0m
echo.
pause
goto exit

:existingVersionError
echo.
echo.[91mSetup %setup% already exists[0m
echo.
pause
goto exit

:exit
rem cleanup
set setup=
set version=
