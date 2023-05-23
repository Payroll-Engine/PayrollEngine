@echo off

REM --- arguments ---
if "%~1"=="" goto status

:update
if "%~1"=="%NamespacePayroll%" goto status
if "%~1"=="reset" goto reset

:set
call PayrollConsole UserVariable NamespacePayroll %1 /wait
goto exit

:reset
echo Previous namespace: %NamespacePayroll%
call PayrollConsole UserVariable NamespacePayroll /remove /wait
goto exit

:status
call PayrollConsole UserVariable NamespacePayroll /wait
goto exit

:undefined
echo Namespace not defined
echo.
pause
goto exit

:exit
