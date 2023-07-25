@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete StartTenant /trydelete
call %console% PayrollImport Basic.json
call %console% PayrollImport Insurance.json
call %console% PayrollImport Company.json
call %console% PayrollImport Report.json
rem build payroll results for the report
call %console% PayrunEmployeeTest Company.Test.et.json
