@echo off

rem console
rem do not use the environment variable "%PayrollConsole%"
set console=%~dp0..\Bin\PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe

rem --- release version ---
call %console% UserVariable PayrollEngineSetupVersion $ProductVersion$ /wait

rem cleanup
set console=
