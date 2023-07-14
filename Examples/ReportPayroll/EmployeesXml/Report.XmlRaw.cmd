@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% Report tenant:Report.Tenant user:peter.schmid@foo.com regulation:Report.Regulation report:EmployeesXml culture:de-CH /xmlraw /shellopen
