@echo off
echo [96mPayroll Engine Release Build[0m
echo.

rem --- release version ---
set version=PayrollConsole
if "%PayrollEngineReleaseVersion%" == "" goto missingVersionError

rem --- archvive file ---
set archive=%~dp0..\Bin\PayrollEngine_%version%.zip
rem cleanup
if exist %archive% goto existingVersionError

rem --- compress only switch ---
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

rem --- outout archive ---
:compressRelease
echo.
echo building release archive %archive%

rem compression
echo adding to archive: release files...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Release\*.* > nul
echo adding to archive: db query tool...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Bin\PayrollEngine.SqlServer.DbQuery > nul
echo adding to archive: payroll backend...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Bin\PayrollEngine.Backend > nul
echo adding to archive: payroll console...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Bin\PayrollEngine.PayrollConsole > nul
echo adding to archive: web application...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Bin\PayrollEngine.WebApp > nul
echo adding to archive: schemas...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Schemas > nul
echo adding to archive: examples...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Examples > nul
echo adding to archive: tests...
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %archive% %~dp0..\Tests > nul

echo.
echo.
pause
goto exit

:missingVersionError
echo [91mMissing release version [0m
echo.
pause
goto exit

:existingVersionError
echo [91mVersion %archive% already exists [0m
echo.
pause
goto exit

:exit
rem cleanup
set version=
set archive=
