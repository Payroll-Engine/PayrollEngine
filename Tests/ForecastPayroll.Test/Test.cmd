@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ForecastPayroll /trydelete
call %console% PayrunTest *.pt.json
