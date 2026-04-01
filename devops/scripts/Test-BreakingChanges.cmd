@echo off
setlocal

set REPOS_ROOT=C:\Shared\PayrollEngine\Repos
set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%Update-BreakingChanges.ps1
set REPORT_PATH=%REPOS_ROOT%\breaking-changes-preview.md

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" ^
    -ReposRoot "%REPOS_ROOT%" ^
    -BaselineRef "HEAD~1" ^
    -SkipReleaseNotes ^
    -ReportPath "%REPORT_PATH%"

set EXIT_CODE=%ERRORLEVEL%

echo.
if %EXIT_CODE% == 0 (
    echo [OK] No breaking changes detected.
) else if %EXIT_CODE% == 1 (
    echo [!!] Breaking changes detected - check output above.
    echo [!!] Verify all breaking changes are documented in RELEASE_NOTES.md
) else (
    echo [!!] Infrastructure failure - detection aborted.
)

if exist "%REPORT_PATH%" (
    echo.
    echo Report written to: %REPORT_PATH%
)

echo.
pause
endlocal
exit /b %EXIT_CODE%
