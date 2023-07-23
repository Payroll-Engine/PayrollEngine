@echo off

echo ********** Payroll Engine Build Release Documents **********

rem --- version check ---
:versionCheck
set version=%PayrollEngineSetupVersion%
if "%version%" == "" goto missingVersionError

rem --- scripting reference ---
:scriptReference
echo.
echo ---- Scripting Reference ----
set targetFile=%~dp0..\Release\%version%\ScriptReference_%version%.zip
echo building scripting reference documentation...
pushd %~dp0..\..\PayrollEngine.Client.Scripting\docfx\
call Static.Build.cmd
popd
echo compressing...
7z a -ssw -r -tzip -y %targetFile% %~dp0..\..\PayrollEngine.Client.Scripting\docfx\_site\*.* > nul
echo.
echo [92mScripting reference documentation created %targetFile%[0m

rem --- services reference ---
:serviceReference
echo.
echo ---- Services Reference ----
set targetFile=%~dp0..\Release\%version%\ServicesReference_%version%.zip
echo building client services reference documentation...
pushd %~dp0..\..\PayrollEngine.Client.Services\docfx\
call Static.Build.cmd
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
