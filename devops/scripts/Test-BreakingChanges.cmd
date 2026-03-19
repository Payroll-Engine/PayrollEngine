@echo off
setlocal

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%Update-BreakingChanges.ps1

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -ConfirmReleaseNotes

set EXIT_CODE=%ERRORLEVEL%

echo.
if %EXIT_CODE% == 0 (
    echo [OK] No breaking changes detected.
) else if %EXIT_CODE% == 1 (
    echo [!!] Breaking changes detected - check output above.
) else (
    echo [!!] Infrastructure failure - detection aborted.
)

echo.
pause
endlocal
exit /b %EXIT_CODE%
