@echo off
call PayrollConsole TenantDelete SimplePayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Lookups.json
call PayrollConsole PayrollImport Payroll.Jobs.json
call PayrollConsole PayrollResults SimplePayroll 2 /wait
