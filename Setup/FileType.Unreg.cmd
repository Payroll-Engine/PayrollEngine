@echo OFF
rem -----------------------------------------------------------------
rem Payroll Engine - File Type Unregister (.pecmd)
rem -----------------------------------------------------------------
echo Payroll Engine File Type Unregister 

rem --- check for admin user
rem see https://stackoverflow.com/a/7986021
:permission
net session >nul 2>&1
if %errorLevel% neq 0 goto permerror

rem --- const
set REG_EXT=.pecmd
set REG_NAME=PayrollEngine.Console

:disassociate
rem --- disassociate file type
echo.
echo Disassociate file extension %REG_EXT%...
echo.
rem see https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc770920(v=ws.11)
rem note the space after the equal sign
assoc %REG_EXT%= 
if %ERRORLEVEL% neq 0 goto regerror

:unregister
rem --- unregister file type
echo.
echo Unregister file type %REG_NAME%...
echo.
rem see https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/cc771394(v=ws.11)
ftype %REG_NAME%=
if %ERRORLEVEL% neq 0 goto regerror
goto success

rem --- permission error
:permerror
echo.
echo Please run this command as Administrator!
echo.
pause
goto exit

rem --- reg error
:regerror
echo.
echo Error in file type registration
echo.
pause
goto exit

rem --- success
:success
echo.
echo File type registartion successfully removed
echo.
pause
goto exit

rem --- exit
:exit
