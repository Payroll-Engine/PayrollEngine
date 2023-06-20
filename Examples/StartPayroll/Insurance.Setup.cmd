@echo off
call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrollImport Insurance.json
call PayrollConsole PayrunEmployeeTest Insurance.Test.et.json /showall
pause
