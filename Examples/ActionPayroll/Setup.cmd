@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

call PayrollConsole TenantDelete ActionTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole CaseTest Test.ct.json /showall %args%
