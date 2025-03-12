@ECHO off

rem --- clear .net cache
echo Clearing .NET NuGet local cache...
dotnet nuget locals all --clear
if %ERRORLEVEL% neq 0 goto error

rem --- clear build cache
echo.
echo Clearing local NuGet build cache...
if exist ..\Packages\*.* del ..\Packages\*.* /Q
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
