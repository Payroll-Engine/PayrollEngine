@echo off

echo ********** Payroll Engine Build Release Swagger **********

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
