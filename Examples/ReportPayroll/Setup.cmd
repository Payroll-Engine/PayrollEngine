@echo off
call PayrollConsole TenantDelete Report.Tenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call Import.Reports
