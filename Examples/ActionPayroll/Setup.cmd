@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ActionTenant /trydelete
call %console% PayrollImport Payroll.json
call %console% CaseTest Test.ct.json /showall %args%
