@echo off

rem --- version setup ---
:version
if "%PayrollEngineSetupVersion%" == "" goto missingVersion

rem --- confirmation ---
:confirmation
echo Payroll Engine Release Build
echo.
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to build the release [96m%PayrollEngineSetupVersion%[0m..."
echo.

echo ============ Payroll Engine Release Build [START] ============
echo.
call Release.Binaries.cmd
call Release.Swagger.cmd
call Release.Docs.cmd
echo.
echo ============ Payroll Engine Release Build [END] ============
echo.
pause
goto exit

rem missing version
:missingVersion
echo.[91mMissing release version in enviroment variable PayrollEngineSetupVersion[0m
pause>nul|set/p ="Press any key to exit..."
goto exit

rem cleanup
:exit
