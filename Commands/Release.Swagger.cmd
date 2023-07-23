@echo off

echo ********** Payroll Engine Build Release Swagger **********

rem --- version check ---
:versionCheck
set version=%PayrollEngineSetupVersion%
if "%version%" == "" goto missingVersionError

rem --- swagger build ---
:swaggerBuild
echo.
echo building swagger.json...
pushd %~dp0..\..\PayrollEngine.Backend\Commands\
call Swagger.Build.cmd
popd

rem --- swagger copy ---
:swaggerCopy
echo.
echo copy swagger.json...
copy %~dp0..\..\PayrollEngine.Backend\docs\swagger.json %~dp0..\Release\
copy %~dp0..\..\PayrollEngine.Backend\docs\swagger.json %~dp0..\docs\
goto exit

:missingVersionError
echo.
echo.[91mMissing setup version[0m
echo.
pause
goto exit

:exit
rem cleanup
set version=
