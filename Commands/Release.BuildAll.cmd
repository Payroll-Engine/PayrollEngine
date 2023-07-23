@echo off

echo ============ Payroll Engine Release Build ============
echo.
call Release.Binaries.cmd
call Release.Swagger.cmd
call Release.Docs.cmd
echo.
pause
