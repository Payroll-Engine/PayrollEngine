@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete tenant:StartTenant /trydelete
call %console% PayrollImport Basic.json /wait
