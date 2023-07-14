@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

call PayrollConsole TenantDelete ExtendedTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrunEmployeeTest Test.et.json /showall %args%
