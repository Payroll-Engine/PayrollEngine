@echo off

rem --- release version ---
if "%PayrollEngineReleaseVersion%" == "" goto missingVersionError

rem --- archvive file ---
set archive=%~dp0..\Bin\PayrollEngine_%PayrollEngineReleaseVersion%.zip
rem cleanup
if exist %archive% goto existingVersionError

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

rem --- outout archive ---
:compressRelease
echo.
echo building release archive %archive%

rem release files
echo adding to archive: release files...
7z a -ssw -r -tzip -y %archive% %~dp0..\Release\*.* > nul
rem db query tool
echo adding to archive: db query tool...
7z a -ssw -r -tzip -y %archive% %~dp0..\Bin\PayrollEngine.SqlServer.DbQuery > nul
rem payroll backend
echo adding to archive: payroll backend...
7z a -ssw -r -tzip -y %archive% %~dp0..\Bin\PayrollEngine.Backend > nul
rem payroll console
echo adding to archive: payroll console...
7z a -ssw -r -tzip -y %archive% %~dp0..\Bin\PayrollEngine.PayrollConsole > nul
rem web application
echo adding to archive: web application...
7z a -ssw -r -tzip -y %archive% %~dp0..\Bin\PayrollEngine.WebApp > nul
rem schemas
echo adding to archive: schemas...
7z a -ssw -r -tzip -y %archive% %~dp0..\Schemas > nul
rem tests
echo adding to archive: tests...
7z a -ssw -r -tzip -y %archive% %~dp0..\Tests > nul
rem examples
echo adding to archive: examples...
7z a -ssw -r -tzip -y %archive% %~dp0..\Examples > nul
rem documents
echo adding to archive: documents...
7z a -ssw -r -tzip -y %archive% %~dp0..\docs > nul

echo.
echo.
pause
goto exit

:missingVersionError
echo.
echo.[91mMissing release version[0m
echo.
pause
goto exit

:existingVersionError
echo.
echo.[91mArchive %archive% already exists[0m
echo.
pause
goto exit

:exit
rem cleanup
set archive=
