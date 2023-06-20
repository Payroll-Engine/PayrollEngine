@echo off
call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrunEmployeeTest Basic.Test.et.json /showall
pause
