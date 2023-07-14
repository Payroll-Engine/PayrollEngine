@echo off

rem server port
set backendport=44354

pushd %~dp0PayrollEngine.Backend\
start dotnet PayrollEngine.Backend.Server.dll --urls=https://localhost:%backendport%/
popd

set backendport=
