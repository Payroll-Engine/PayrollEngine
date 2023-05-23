@ECHO off
dotnet nuget locals all --clear
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit