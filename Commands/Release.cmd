@echo off

rem --- release configuration ---
set version=0.5.0-230715

rem compress only switch
rem goto compressRelease

:publishBinaries
echo.
echo publishing system tools...
call Publish.Tools
echo building nugets...
call Pack.All %1
echo publishing backend...
call Publish.Backend
echo publishing payroll console...
call Publish.PayrollConsole
echo publishing web application...
call Publish.WebApp

REM --- outout archive ---
:compressRelease
echo.
echo building release archive %TargetFile%

set TargetFile=%~dp0..\Bin\PayrollEngine_%version%.zip
REM cleanup
if exist %TargetFile% DEL %TargetFile%

REM compression
echo adding to archive: release files...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Release\*.* > nul
echo adding to archive: db query tool...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Bin\PayrollEngine.SqlServer.DbQuery > nul
echo adding to archive: payroll backend...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Bin\PayrollEngine.Backend > nul
echo adding to archive: payroll console...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Bin\PayrollEngine.PayrollConsole > nul
echo adding to archive: web application...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Bin\PayrollEngine.WebApp > nul
echo adding to archive: schemas...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Schemas > nul
echo adding to archive: examples...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Examples > nul
echo adding to archive: tests...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetFile% %~dp0..\Tests > nul

pause
