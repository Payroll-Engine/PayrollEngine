@echo off
call PayrollConsole TenantDelete ActionTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
