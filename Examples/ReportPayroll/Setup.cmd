@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete Report.Tenant /trydelete
call %console% PayrollImport Payroll.json
call %console% ChangePassword Report.Tenant lucy.smith@foo.com @ayroll3ngine
call Import.Reports
