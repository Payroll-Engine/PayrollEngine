@ECHO off

rem --- clear .net cache
echo Clearing .NET NuGet local cache...
dotnet nuget locals all --clear
if %ERRORLEVEL% neq 0 goto error

rem --- clear build cache
echo.
echo Clearing local NuGet build cache...
if exist ..\Packages\PayrollEngine.Core.*.* del ..\Packages\PayrollEngine.Core.*.* /Q
if exist ..\Packages\PayrollEngine.Serilog.*.* del ..\Packages\PayrollEngine.Serilog.*.* /Q
if exist ..\Packages\PayrollEngine.Document.*.* del ..\Packages\PayrollEngine.Document.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Core.*.* del ..\Packages\PayrollEngine.Client.Core.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Scripting.*.* del ..\Packages\PayrollEngine.Scripting.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Test.*.* del ..\Packages\PayrollEngine.Test.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Services.*.* del ..\Packages\PayrollEngine.Services.*.* /Q
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
