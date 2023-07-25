@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete StartTenant /trydelete
call %console% PayrollImport Basic.json
rem --- web application login ---
call %console% ChangePassword StartTenant lucy.smith@foo.com @ayroll3ngine
call %console% PayrollImport Insurance.json
call %console% PayrollImport Company.json
call %console% PayrollImport Report.json
