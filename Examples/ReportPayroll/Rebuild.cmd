@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% RegulationRebuild Payroll.Report Payroll.Report Report
pause