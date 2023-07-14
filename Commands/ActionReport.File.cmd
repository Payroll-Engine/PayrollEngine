@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

call %console% ActionReport %~dp0..\.bin\Provider.Api\PayrollEngine.Client.Scripting.dll > ActionReport.txt
