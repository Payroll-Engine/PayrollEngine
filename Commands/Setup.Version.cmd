@echo off

rem console
set console=PayrollConsole
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

rem --- release version ---
call %console% UserVariable PayrollEngineSetupVersion $ProductVersion$ /wait

rem cleanup
set console=
