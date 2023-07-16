@echo off

rem --- web app url ---
set webappserverurl=https://localhost
if not "%PayrollEnginewebappserverurl%" == "" set webappserverurl=%PayrollEnginewebappserverurl%

rem --- web app port ---

set webappserverport=7179
if not "%PayrollEnginewebappserverport%" == "" set webappserverport=%PayrollEnginewebappserverport%

rem --- start web app ---
pushd %~dp0PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=%webappserverurl%:%webappserverport%/
popd

rem --- cleanup ---
set webappserverport=
set webappserverurl=
