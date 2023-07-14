@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete DerivedPayroll /trydelete
call %console% PayrollImport Payroll.json
call %console% PayrollImport Payroll.Values.json
call %console% PayrollImport Payroll.Jobs.json %1
