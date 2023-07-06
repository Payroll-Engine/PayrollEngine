@echo off
call PayrollConsole TenantDelete ActionTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole CaseTest Test.ct.json /showall /wait
