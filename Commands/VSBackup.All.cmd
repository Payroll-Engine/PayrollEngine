@echo off

set VSBACKUP_ROOT=1

set START_DIR=%cd%

pushd %~dp0..\..\PayrollEngine.Core
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Serilog
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Document
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Document.Syncfusion
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Client.Core
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Client.Scripting
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Client.Test
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Client.Services
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Client.Tutorials
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\Regulation.CH.Swissdec
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.Backend
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.PayrollConsole
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.WebApp
call VSBackup %START_DIR%
popd

pushd %~dp0..\..\PayrollEngine.AdminApp
call VSBackup %START_DIR%
popd

rem root repo
pushd %~dp0..\..\PayrollEngine
call VSBackup %START_DIR%
popd

:exit
set VSBACKUP_ROOT=