@echo off
call PayrollConsole TenantDelete MinimalPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
rem call PayrollConsole PayrollImport Payroll.Jobs.json
rem call PayrollConsole PayrollResults MinimalPayroll 2 /wait
