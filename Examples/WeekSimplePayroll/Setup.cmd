@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete WeekSimplePayroll /trydelete
call %console% PayrollImport Payroll.json
call %console% PayrollImport Payroll.Values.json
call %console% PayrollImport Payroll.Jobs.json
call %console% PayrollResults WeekSimplePayroll 1 %args%
