@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% ReportExecute Employees.data.json ReportTest peter.schmid@foo.com ReportTest EmployeesReport German
