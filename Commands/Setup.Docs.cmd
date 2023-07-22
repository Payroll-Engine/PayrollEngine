@echo off

echo Payroll Engine Document Setup

rem --- version check ---
:versionCheck
set version=%PayrollEngineSetupVersion%
if "%version%" == "" goto missingVersionError

rem --- scripting reference ---
:scriptReference
echo.
echo ---- Scripting Reference ----
set targetFile=%~dp0..\Bin\ScriptReference_%version%.zip
echo building scripting reference documentation...
pushd %~dp0..\..\PayrollEngine.Client.Scripting\docfx\
call Build.cmd
popd
echo compressing...
7z a -ssw -r -tzip -y %targetFile% %~dp0..\..\PayrollEngine.Client.Scripting\docfx\_site\*.* > nul
echo.
echo [92mScripting reference documentation created %targetFile%[0m

rem --- client services reference ---
:clientServiceReference
echo.
echo ---- Client Services Reference ----
set targetFile=%~dp0..\Bin\ClientServicesReference_%version%.zip
echo building client services reference documentation...
pushd %~dp0..\..\PayrollEngine.Client.Services\docfx\
call Build.cmd
popd
echo compressing...
7z a -ssw -r -tzip -y %targetFile% %~dp0..\..\PayrollEngine.Client.Services\docfx\_site\*.* > nul
echo.
echo [92mClient services reference documentation created %targetFile%[0m
goto exit

:missingVersionError
echo.
echo.[91mMissing setup version[0m
echo.
pause
goto exit

:exit
rem cleanup
set targetFile=
set version=
