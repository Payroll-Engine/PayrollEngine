@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ExtendedTenant /trydelete
call %console% PayrollImport Payroll.json
call %console% PayrunEmployeeTest Test.et.json /showall %args%
