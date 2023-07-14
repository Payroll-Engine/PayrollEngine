@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete ReportTest /trydelete
call %console% PayrollImport Payroll.json
call %console% ReportTest *.rt.json /showall
