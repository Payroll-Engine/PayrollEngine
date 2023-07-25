@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% ActionReport %~dp0..\Bin\PayrollEngine.Backend\PayrollEngine.Client.Scripting.dll > ActionReport.txt
