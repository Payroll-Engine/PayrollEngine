@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

rem call %console% TenantDelete CaseTest /trydelete
rem call %console% PayrollImport Payroll.json
call %console% CaseTest Test.Salary.ct.json /showall /wait
