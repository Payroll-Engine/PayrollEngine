@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete WeekSimplePayroll /trydelete
call %console% PayrollImport Payroll.json
call %console% ChangePassword WeekSimplePayroll lucy.smith@foo.com @ayroll3ngine
call %console% PayrollImport Payroll.Values.json
call %console% PayrollImport Payroll.Jobs.json
call %console% PayrollResults WeekSimplePayroll 1 %args%
