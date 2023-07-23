@echo off

echo ============ Payroll Engine Release Build [START] ============
echo.
call Release.Binaries.cmd
call Release.Swagger.cmd
call Release.Docs.cmd
echo.
echo ============ Payroll Engine Release Build [END] ============
echo.
pause
