@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

call PayrollConsole TenantDelete WeekSimplePayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Jobs.json
call PayrollConsole PayrollResults WeekSimplePayroll 1 %args%
