@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% Report tenant:Report.Tenant user:lucy.smith@foo.com regulation:Report.Regulation report:CumulativeJournal culture:de-CH /pdf /shellopen
