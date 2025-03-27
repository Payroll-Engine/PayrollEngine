@echo off

echo Set Payroll Set Release Version

rem --- version setup ---
:version
set version=0.9.0-beta.6

rem --- confirmation ---
:confirmation
echo.
echo current version        [96m%PayrollEngineSetupVersion%[0m
echo new version            [96m%version%[0m
echo.
if "%version%" == "%PayrollEngineSetupVersion%" goto noChanges
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to set the version [96m%version%[0m..."
echo.

rem --- console ---
set console=%~dp0..\Bin\Console\PayrollEngine.PayrollConsole.exe
if not "%PayrollConsole%" == "" set console=%PayrollConsole%

rem --- release version ---
call %console% UserVariable PayrollEngineSetupVersion %version%
pause
goto exit

rem no changes
:noChanges
pause>nul|set/p ="Version unchanged, press any key to exit..."

rem cleanup
:exit
set console=
set version=
