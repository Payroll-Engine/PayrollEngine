@echo off

rem default: wait after results
set args=/wait
if not "%1" == "" set args=%1

call PayrollConsole TenantDelete SimplePayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Lookups.json
call PayrollConsole PayrollImport Payroll.Jobs.json
call PayrollConsole PayrollResults SimplePayroll 2 %args%
