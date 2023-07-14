@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete StartTenant /trydelete
call %console% PayrollImport Basic.json
call %console% PayrollImport Insurance.json
call %console% PayrollImport Company.json
call %console% PayrollImport Report.json
rem build payroll results
call %console% PayrunEmployeeTest Company.Test.et.json
call %console% Report tenant:StartTenant user:lucy.smith@foo.com regulation:StartRegulation report:StartReport parameterFile:Report.Parameters.json culture:en /pdf /shellopen
