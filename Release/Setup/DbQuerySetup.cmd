@echo off
rem --- current process ---
set PayrollDbQuery=%~dp0..\PayrollEngine.SqlServer.DbQuery\PayrollEngine.SqlServer.DbQuery.exe
rem --- future processes ---
setx PayrollDbQuery "%~dp0..\PayrollEngine.SqlServer.DbQuery\PayrollEngine.SqlServer.DbQuery.exe" > nul
