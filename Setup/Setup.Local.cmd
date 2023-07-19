@echo off

rem --- title ---
echo.[7m --- Payroll Engine Local Setup --- [0m
echo.

set config=%~dp0engine.json
set console=%~dp0PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe
set dbQuery=%~dp0PayrollEngine.SqlServer.DbQuery\PayrollEngine.SqlServer.DbQuery.exe

rem --- confirmation ---
:confirmation
rem payroll configuration
echo [97mPayroll configuration[0m
if %PayrollConfiguration% == %config% (
echo   [92m%PayrollConfiguration%[0m
) else (
echo   old: [96m%PayrollConfiguration%[0m
echo   new: [93m%config%[0m
)
echo.

rem payroll console
echo [97mPayroll console[0m
if %PayrollConsole% == %console% (
echo   [92m%PayrollConsole%[0m
) else (
echo   old: [96m%PayrollConsole%[0m
echo   new: [93m%console%[0m
)
echo.

rem db query
echo [97mPayroll database query[0m
if %PayrollDbQuery% == %dbQuery% (
echo   [92m%PayrollDbQuery%[0m
) else (
echo   old: [96m%PayrollDbQuery%[0m
echo   new: [93m%dbQuery%[0m
)
echo.

rem --- confirmation ---
if %PayrollConfiguration% == %config% if %PayrollConsole% == %console% if %PayrollDbQuery% == %dbQuery% goto noChanges
pause>nul|set/p ="Press <Ctrl+C> to exit or any other key to apply local settings..."
echo.

rem --- PayrollConfiguration ---
:setupConfiguration
set PayrollConfiguration=%config%
rem --- future processes ---
setx PayrollConfiguration "%config%" > nul

rem --- payroll console ---
:setupPayrollConsole
set PayrollConsole=%console%
rem --- future processes ---
setx PayrollConsole "%console%" > nul

rem --- payroll db query ---
:setupDbQuery
set PayrollDbQuery=%dbQuery%
rem --- future processes ---
setx PayrollDbQuery "%dbQuery%" > nul
set query=%PayrollDbQuery%
goto exit

rem --- cleanup ---
:noChanges
echo.
echo No changes
echo.
pause>nul|set/p ="Press any key to exit..."

rem --------------------------- error & exit ---------------------------

rem --- cleanup ---
:exit
set config=
set console=
set dbQuery=
