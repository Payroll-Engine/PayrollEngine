@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ActionTenant /trydelete
call %console% PayrollImport Payroll.json
call %console% ChangePassword ActionTenant lucy.smith@foo.com @ayroll3ngine
