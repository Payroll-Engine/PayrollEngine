@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% ScriptExport devscripts SimplePayroll lucy.smith@foo.com mario.nunez@foo.com SimplePayroll.Derived1 SimplePayroll /wait

