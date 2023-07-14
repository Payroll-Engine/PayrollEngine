@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% Report tenant:StartTenant user:lucy.smith@foo.com regulation:StartRegulation report:StartReport parameterFile:Report.Parameters.json culture:de /pdf /shellopen
