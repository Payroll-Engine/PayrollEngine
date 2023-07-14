@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrollImport Insurance.json
call PayrollConsole PayrollImport Company.json
call PayrollConsole PayrollImport Report.json
call PayrollConsole PayrunEmployeeTest Company.Test.et.json %args%
