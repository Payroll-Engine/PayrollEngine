@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete Payroll.Test /trydelete
call %console% TenantDelete Payroll.Test.Shared /trydelete
call %console% PayrunTest *.pt.json
