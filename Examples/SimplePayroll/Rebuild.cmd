@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% RegulationRebuild SimplePayroll SimplePayroll
call %console% PayrunRebuild SimplePayroll SimplePayrollPayrun1
call %console% PayrunRebuild SimplePayroll SimplePayrollPayrun2
pause