@echo off

rem directories
set PayrollEnginePackageDir=%~dp0..\Packages
set PayrollEngineSchemaDir=%~dp0..\Schemas

rem parameter
if "%~1"=="" set goto help
if not exist %~dp0..\..\%1 goto help

rem configuration
set PackConfiguration=Release
if "%~2"=="Debug" set PackConfiguration=%2
if "%~2"=="Release" set PackConfiguration=%2

rem pack
echo.
echo ---------- Pack - %1 (%PackConfiguration%) ----------
dotnet pack %~dp0..\..\%1 --configuration %PackConfiguration%
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause
goto exit

:help
echo Usage: Pack ProjectName.csprj [Debug | Release]
pause
goto exit

:exit
set PayrollEnginePackageDir=
set PayrollEngineSchemaDir=
set PackConfiguration=
