@echo off

rem --- backend url ---
rem default backend url
set backendServerUrl=https://localhost
rem environment override backend url
if not "%PayrollEngineBackendUrl%" == "" set backendServerUrl=%PayrollEngineBackendUrl%

rem --- backend port ---
rem default backend port
set backendServerPort=44354
rem environment override backend port
if not "%PayrollEngineBackendPort%" == "" set backendServerPort=%PayrollEngineBackendPort%

rem --- start backend server ---
pushd %~dp0PayrollEngine.Backend\
start dotnet PayrollEngine.Backend.Server.dll --urls=%backendServerUrl%:%backendServerPort%/
popd

rem --- cleanup ---
set backendServerPort=
set backendServerUrl=
