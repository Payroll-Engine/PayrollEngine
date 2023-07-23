@echo off
rem Use "Setup.Build.cmd nopub" to skip binary publish

echo ********** Payroll Engine Build Release Binaries **********

rem --- version check ---
:versionCheck
set version=%PayrollEngineSetupVersion%
if "%version%" == "" goto missingVersionError

rem --- setup file ---
set setup=%~dp0..\Release\%version%\PayrollEngine_%version%.zip
rem existing setup test
if exist %setup% goto existingVersionError

echo.
echo target version: %version%
echo.
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to continue..."

rem --- compress only switch ---
if "%1" == "nopub" goto buildArchive
rem goto buildArchive

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
:buildArchive
echo.
echo ------------------- Building archive -------------------
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

rem --- comlete ---
:buildComplete
echo.
echo.[92mSetup completed %setup%[0m
echo.
goto exit

:existingVersionError
echo.
echo.[91mSetup version already exists %setup%[0m
echo.
pause
goto exit

:missingVersionError
echo.
echo.[91mMissing setup version[0m
echo.
pause
goto exit

:exit
rem cleanup
set setup=
set console=
set version=
