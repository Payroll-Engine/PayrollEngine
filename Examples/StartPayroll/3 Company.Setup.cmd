@echo off
call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrollImport Insurance.json
call PayrollConsole PayrollImport Company.json
call PayrollConsole PayrunEmployeeTest Company.Test.et.json /showall /wait
