@echo off
call PayrollConsole TenantDelete Payroll.Report /trydelete
call PayrollConsole PayrollImport Payroll.json
call Import.Reports
