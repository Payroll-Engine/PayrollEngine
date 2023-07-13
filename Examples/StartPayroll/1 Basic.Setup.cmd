@echo off
call PayrollConsole TenantDelete tenant:StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrunEmployeeTest Basic.Test.et.json /showall /wait

