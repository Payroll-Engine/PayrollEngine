@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete SimplePayroll /trydelete
call %console% PayrollImport Payroll.json
call %console% ChangePassword SimplePayroll lucy.smith@foo.com @ayroll3ngine
call %console% PayrollImport Payroll.Values.json
call %console% PayrollImport Payroll.Lookups.json
call %console% PayrollImport Payroll.Jobs.json
call %console% PayrollResults SimplePayroll 2 %args%
rem pause