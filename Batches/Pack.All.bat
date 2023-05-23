@echo off
echo Payroll Engine package builder

rem configuration
set PackAllConfiguration=Release
if "%~1"=="Debug" set PackAllConfiguration=%1
if "%~1"=="Release" set PackAllConfiguration=%1

rem pack core
call Pack PayrollEngine.Core\Core\PayrollEngine.Core.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack serilog
call Pack PayrollEngine.Serilog\Serilog\PayrollEngine.Serilog.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack document
call Pack PayrollEngine.Document\Document\PayrollEngine.Document.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack document syncfusion
call Pack PayrollEngine.Document.Syncfusion\Syncfusion\PayrollEngine.Document.Syncfusion.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack client core
call Pack PayrollEngine.Client.Core\Client.Core\PayrollEngine.Client.Core.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack client test
call Pack PayrollEngine.Client.Test\Client.Test\PayrollEngine.Client.Test.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack client scripting
call Pack PayrollEngine.Client.Scripting\Client.Scripting\PayrollEngine.Client.Scripting.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
rem pack client services
call Pack PayrollEngine.Client.Services\Client.Services\PayrollEngine.Client.Services.csproj %PackAllConfiguration%
if %ERRORLEVEL% neq 0 goto error
goto exit

:error
echo Error
pause
goto exit

:exit
set PackAllConfiguration=
