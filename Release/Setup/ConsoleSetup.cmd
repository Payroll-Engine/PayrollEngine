@echo off
rem --- current process ---
set PayrollConsole=%~dp0..\PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe
rem --- future processes ---
setx PayrollConsole "%~dp0..\PayrollEngine.PayrollConsole\PayrollEngine.PayrollConsole.exe" > nul
