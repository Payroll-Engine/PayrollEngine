@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

rem --- release version ---
call %console% UserVariable PayrollEngineReleaseVersion $ProductVersion$ /wait

rem cleanup
set console=
