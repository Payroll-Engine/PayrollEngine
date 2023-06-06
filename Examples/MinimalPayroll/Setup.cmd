@echo off
call PayrollConsole TenantDelete MinimalPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Jobs.json
call PayrollConsole PayrollResults MinimalPayroll 10 /wait
