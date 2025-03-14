@echo off
rem Use "Setup.Build.cmd nopub" to skip binary publish

echo ********** Payroll Engine Build Release Binaries **********

rem --- version check ---
:versionCheck
set version=%PayrollEngineSetupVersion%
if "%version%" == "" goto missingVersionError

rem --- setup files ---
set fullSetup=%~dp0..\Releases\%version%\PayrollEngine_%version%.zip
if exist %fullSetup% goto existingVersionError
set clientSetup=%~dp0..\Releases\%version%\PayrollEngineClient_%version%.zip
if exist %clientSetup% goto existingVersionError

rem --- compress only switch ---
if "%1" == "nopub" goto buildFullSetup
rem goto buildFullSetup
rem goto buildClientSetup

rem --- clear .net cache ---
:clearNugets
call NuGetClearCache.cmd

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
echo publishing admin application...
call Publish.AdminApp.cmd

rem --- action reference ---
:actionReference
echo.
echo ------------------- Building action reference -------------------
echo.
pushd %~dp0..\docs\
%~dp0..\Bin\Console\PayrollEngine.PayrollConsole.exe ActionReport %~dp0..\Bin\Backend\PayrollEngine.Client.Scripting.dll
popd

rem --- local setup ---
:buildFullSetup
echo.
echo ------------------- Building setup -------------------
echo.
rem setup files
echo adding setup files...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Setup\*.* > nul
rem admin tool
echo compressing admin tool...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Bin\Admin > nul
rem payroll backend
echo compressing payroll backend...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Bin\Backend > nul
echo adding database files...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Bin\Backend > nul
rem payroll console
echo compressing payroll console...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Bin\Console > nul
rem web application
echo compressing web application...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Bin\WebApp > nul
rem schemas
echo compressing schemas...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Schemas > nul
rem tests
echo compressing tests...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Tests > nul
rem examples
echo compressing examples...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\Examples > nul
rem documents
echo compressing documents...
7z a -ssw -r -tzip -y %fullSetup% %~dp0..\docs > nul

:buildClientSetup
echo.
echo ------------------- Building client setup -------------------
echo.
rem setup files
echo adding setup files...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Setup\*.* > nul
rem admin tool
echo compressing admin tool...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Bin\Admin > nul
rem payroll console
echo compressing payroll console...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Bin\Console > nul
rem schemas
echo compressing schemas...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Schemas > nul
rem tests
echo compressing tests...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Tests > nul
rem examples
echo compressing examples...
7z a -ssw -r -tzip -y %clientSetup% %~dp0..\Examples > nul

rem --- complete ---
:buildComplete
echo.
echo.[92mSetup completed %fullSetup%[0m
echo.
goto exit

:existingVersionError
echo.
echo.[91mSetup version already exists %fullSetup%[0m
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
set fullSetup=
set clientSetup=
set version=
