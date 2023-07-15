@echo off

rem --- setup configuration ---
set dbMinVersion=1.0.0

rem --- setup system tools ---
call ConsoleSetup.cmd
call DbQuerySetup.cmd
rem tool setup successfully

rem --- query tool ---
set query=PayrollDbQuery
if not "%PayrollDbQuery%" == "" set query=%PayrollDbQuery%

rem --- test available database server ---
:testDatabaseServer
call %query% TestServer
if %ERRORLEVEL% neq 0 goto error

rem --- test available database version ---
:testDatabaseVersion
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbMinVersion%
if %ERRORLEVEL% neq 0 goto setupDatabase
rem database version available
goto setupExamples

rem --- setup database ---
:setupDatabase
call %query% Script ..\Database\DatabaseVersion_%dbMinVersion%.sql
if %ERRORLEVEL% neq 0 goto error
rem test database setup
call %query% TestVersion Version MajorVersion MinorVersion SubVersion %dbMinVersion%
if %ERRORLEVEL% neq 0 goto error
rem database setup successfully
goto setupExamples

rem --- setup examples ---
:setupExamples
rem start backend server
call ..\BackendServer.cmd
rem setup examples
call ..\Examples\Setup.All.cmd
rem examples setup successfully
goto exit

:error
pause
goto exit

:exit
set query=
set dbMinVersion=
