@echo OFF
rem -----------------------------------------------------------------
rem Payroll Engine - File Type Registration (.pecmd)
rem -----------------------------------------------------------------
echo Payroll Engine File Type Registration

rem --- check for admin user
rem see https://stackoverflow.com/a/7986021
:permission
net session >nul 2>&1
if %errorLevel% neq 0 goto permerror

rem --- const
set REG_EXT=.pecmd
set REG_NAME=PayrollEngine.Console
set EXE_FILE=PayrollEngine.PayrollConsole.exe

rem --- exe path
set EXE_PATH=%1
rem parameter or current directory
if "%1"=="" (SET EXE_PATH=%~dp0)
if exist %EXE_PATH%\%EXE_FILE% goto register
rem console subfolder in setup
set EXE_PATH=%~dp0\Console
if exist %EXE_PATH%\%EXE_FILE% goto register

rem missing executable
goto error

rem --- register file type
:register
echo.
echo Register file type %REG_NAME%...
echo.
rem see https://stackoverflow.com/a/46900103
ftype %REG_NAME%=%EXE_PATH%\%EXE_FILE% "%%1"
if %ERRORLEVEL% neq 0 goto regerror

rem --- associate file type
:associate
echo.
echo Associate file extension %REG_EXT%...
echo.
assoc %REG_EXT%=%REG_NAME%
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

rem --- executbale error
:error
echo.
echo Invalid registartion executable %REG_FILE%
echo.
pause
goto exit

rem --- help
:help
echo Usage: FileType.Reg <ConsoleProgramPath>
echo.
echo Administrator rights required
echo.
echo Example: FileType.Reg
echo Example: FileType.Reg C:\PayrollEngine\Console
echo.
pause
goto exit

rem --- success
:success
echo.
echo File type successfully registrated
echo.
pause
goto exit

rem --- exit
:exit
set EXE_PATH=
set EXE_FILE=
set REG_EXT=
set REG_NAME=
