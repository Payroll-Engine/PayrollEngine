@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% TenantDelete WeekCalendar.Test /trydelete
