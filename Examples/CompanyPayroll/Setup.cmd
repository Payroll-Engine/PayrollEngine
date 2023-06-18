@echo off
call PayrollConsole TenantDelete CompanyPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call Test
