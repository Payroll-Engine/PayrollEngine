@echo off
echo Payroll Engine Libraries Publisher

rem --- pack all NuGet libraries
echo.
echo Step 1: Pack all NuGet libraries...
call Pack.All.cmd Release
if %ERRORLEVEL% neq 0 goto error

rem --- clear NuGet local cache (force restore from local feed)
echo.
echo Step 2: Clear NuGet local cache...
dotnet nuget locals all --clear
if %ERRORLEVEL% neq 0 goto error

rem --- publish PayrollConsole (depends on NuGet libraries)
echo.
echo Step 3: Publish PayrollConsole...
call Publish.Console.cmd
if %ERRORLEVEL% neq 0 goto error

echo.
echo Libraries published successfully.
goto exit

:error
echo.
echo Error - Libraries publish failed.
pause

:exit
