@echo off

REM --- arguments ---
if "%~1"=="" goto help
for %%I in (.) do SET ProjectName=%%~nxI
set BackupDirectory=%1
set AdditionalBackupDirectory=%2

REM --- generate file name using the current date and time ---
SET BackupDate=%date:.=%
set BackupDate=%BackupDate: =%
set BackupTime=%time:.=%
set BackupTime=%BackupTime::=%
set BackupTime=%BackupTime: =%
set TargetFile=%ProjectName%_%BackupDate%_%BackupTime%.zip
set TargetPath=%BackupDirectory%\%ProjectName%\%TargetFile%
set AdditionalTargetPath=%AdditionalBackupDirectory%\%ProjectName%\%TargetFile%
set BackupDate=
set BackupTime=

REM --- file info ----
echo.
echo Visual Studio solution backup to archive [%TargetFile%]
echo.

REM --- primary backup (7z target output) ---
echo --- Primary backup ---
set BackupConfigPath=%~dp0
7z a -ssw -r -tzip -y -xr@%BackupConfigPath%VSBackupExcludeList.txt %TargetPath% .\*.* > nul
if exist %BackupDirectory%/%ProjectName%\%TargetFile% (
  echo Backup created [%BackupDirectory%\%ProjectName%]
  echo.
) else (
  echo !!! Compression error to target [%TargetPath%]
  goto error
)

REM --- second backup (primary backup duplicate) ---
if "%~2"=="" goto complete
echo --- Secondary backup ---
if not exist %AdditionalBackupDirectory%\%ProjectName% mkdir %AdditionalBackupDirectory%\%ProjectName%
if %ERRORLEVEL% neq 0 (
  echo !!! Target folder error [%AdditionalBackupDirectory%\%ProjectName%]
  echo.
  goto done
)
rem echo copy %TargetPath% "%AdditionalBackupDirectory%\%ProjectName%\*.*"
copy %TargetPath% "%AdditionalBackupDirectory%\%ProjectName%\*.*" > nul

if exist %AdditionalBackupDirectory%\%ProjectName%\%TargetFile% (
  echo Backup created [%AdditionalBackupDirectory%\%ProjectName%]
) else (
  echo !!! Target copy error [%AdditionalBackupDirectory%\%ProjectName%]
  echo.
  goto done
)

:complete
echo.
echo Backup completed
goto done

:error
echo.
echo Error while creating the backup file %TargetFile%
pause
goto done

:help
echo.
echo usage: VSBackup BackupDirectory [AdditionalBackupDirectory]
echo.
echo Initial directory should be the visual studio solution directory: $(SolutionDir)
echo.
goto exit

:done
set BackupConfigPath=
set ProjectName=
set TargetFile=
set TargetPath=
set AdditionalTargetPath=
set BackupDirectory=

:exit