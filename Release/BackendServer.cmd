@echo off

rem --- backend url ---
set backendserverurl=https://localhost
if not "%PayrollEnginebackendserverurl%" == "" set backendserverurl=%PayrollEnginebackendserverurl%

rem --- backend port ---
set backendserverport=44354
if not "%PayrollEnginebackendserverport%" == "" set backendserverport=%PayrollEnginebackendserverport%

rem --- start backend server ---
pushd %~dp0PayrollEngine.Backend\
start dotnet PayrollEngine.Backend.Server.dll --urls=%backendserverurl%:%backendserverport%/
popd

rem --- cleanup ---
set backendserverport=
set backendserverurl=
