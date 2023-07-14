@echo off

rem default: wait after results
set args=/wait
if not "%1" == "" set args=%1

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete SimplePayroll /trydelete
call %console% PayrollImport Payroll.json
call %console% PayrollImport Payroll.Values.json
call %console% PayrollImport Payroll.Lookups.json
call %console% PayrollImport Payroll.Jobs.json
call %console% PayrollResults SimplePayroll 2 %args%
