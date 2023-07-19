@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% Report Payroll.Report lucy.smith@foo.com Payroll.Report ReportEndQuery de-CH /pdf
pause
