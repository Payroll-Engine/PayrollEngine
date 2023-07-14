@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% PayrollExport SimplePayroll .exports\SimplePayrollRegulation_{timestamp}.json
