@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ExtendedTenant /trydelete
call %console% PayrollImport Payroll.json
call %console% ChangePassword ExtendedTenant lucy.smith@foo.com @ayroll3ngine
