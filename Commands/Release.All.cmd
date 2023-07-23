@echo off

echo ============ Payroll Engine Release Build ============
call Release.Binaries.cmd
call Release.Swagger.cmd
call Release.Docs.cmd
pause
