@echo off
call PayrollConsole TenantDelete WikiTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call Test
pause
