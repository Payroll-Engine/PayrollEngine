@ECHO off
cd /d "%~dp0"

rem --- clear PayrollEngine packages from the global NuGet cache only
rem --- the local feed (..\Packages) is NOT touched, so freshly packed packages stay available
rem --- external packages (FastReport, ClosedXML, Roslyn, ...) are preserved
rem ---
rem --- usage:
rem ---   NuGetClearCache.Global.cmd                  all payrollengine.* packages
rem ---   NuGetClearCache.Global.cmd mcp.tools        packages whose id starts with payrollengine.mcp.tools
rem ---   NuGetClearCache.Global.cmd lex 1.2.0        one package version (payrollengine.lex 1.2.0)
rem ---
rem --- stop running servers first (for example PayrollEngine.Mcp.Server.Pro): locked files cannot be removed

set "CACHE=%userprofile%\.nuget\packages"
set "NAME=%~1"
set "VERSION=%~2"

if "%NAME%"=="" (
    echo Clearing all PayrollEngine packages from the global NuGet cache...
    for /d %%d in ("%CACHE%\payrollengine.*") do call :remove "%%d"
    goto done
)

if not "%VERSION%"=="" (
    echo Clearing payrollengine.%NAME% %VERSION% from the global NuGet cache...
    call :remove "%CACHE%\payrollengine.%NAME%\%VERSION%"
    goto done
)

echo Clearing payrollengine.%NAME%* from the global NuGet cache...
for /d %%d in ("%CACHE%\payrollengine.%NAME%*") do call :remove "%%d"
goto done

:remove
if not exist %1 goto :eof
echo   %~1
rd /s /q %1 2>nul
if exist %1 echo   LOCKED, not removed: %~1
goto :eof

:done
echo.
echo Done. Rebuild the consumers so that they restore the packages from the local feed.
rem --- reset ERRORLEVEL: rd errors (locked files) must not leak into the caller
(exit /b 0)
