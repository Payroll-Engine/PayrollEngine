@ECHO off
cd /d "%~dp0"

rem --- clear only PayrollEngine packages from the global NuGet cache
rem --- (external packages like FastReport, NPOI, Roslyn are preserved)
echo Clearing PayrollEngine NuGet packages from global cache...
for /d %%d in ("%userprofile%\.nuget\packages\payrollengine.*") do rd /s /q "%%d" 2>nul

rem --- reset ERRORLEVEL: rd errors (locked files) must not leak into the local section
(exit /b 0)

rem --- clear build cache (local Packages folder)
echo.
echo Clearing local NuGet build cache...
if exist ..\Packages\PayrollEngine.Core.*.* del ..\Packages\PayrollEngine.Core.*.* /Q
if exist ..\Packages\PayrollEngine.Serilog.*.* del ..\Packages\PayrollEngine.Serilog.*.* /Q
if exist ..\Packages\PayrollEngine.Document.*.* del ..\Packages\PayrollEngine.Document.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Core.*.* del ..\Packages\PayrollEngine.Client.Core.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Scripting.*.* del ..\Packages\PayrollEngine.Client.Scripting.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Test.*.* del ..\Packages\PayrollEngine.Client.Test.*.* /Q
if exist ..\Packages\PayrollEngine.Client.Services.*.* del ..\Packages\PayrollEngine.Client.Services.*.* /Q
if exist ..\Packages\PayrollEngine.Mcp.Core.*.* del ..\Packages\PayrollEngine.Mcp.Core.*.* /Q
if exist ..\Packages\PayrollEngine.Mcp.Tools.Pro.*.* del ..\Packages\PayrollEngine.Mcp.Tools.Pro.*.* /Q
if exist ..\Packages\PayrollEngine.Mcp.Tools.*.* del ..\Packages\PayrollEngine.Mcp.Tools.*.* /Q
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
pause

:exit
