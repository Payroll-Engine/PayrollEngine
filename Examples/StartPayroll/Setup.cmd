@echo off

rem default: wait after tests
set args=/wait
if not "%1" == "" set args=%1

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete StartTenant /trydelete
call %console% PayrollImport Basic.json
call %console% ChangePassword StartTenant lucy.smith@foo.com @ayroll3ngine
call %console% PayrollImport Insurance.json
call %console% PayrollImport Company.json
call %console% PayrollImport Report.json
