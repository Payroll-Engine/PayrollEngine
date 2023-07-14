@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete CaseTest /trydelete
call %console% PayrollImport Payroll.json
call %console% CaseTest *.ct.json
