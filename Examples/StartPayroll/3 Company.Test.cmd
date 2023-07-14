@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% PayrunEmployeeTest Company.Test.et.json /showall /wait