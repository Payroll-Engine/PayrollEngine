@echo off
call PayrollConsole TenantDelete CaseDefPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json %1
