@echo off

rem --- web application server url ---
rem default web application server url
set webAppServerUrl=https://localhost
rem environment override web application server url
if not "%PayrollEnginewebAppUrl%" == "" set webAppServerUrl=%PayrollEnginewebAppUrl%

rem --- web web application server port ---
rem default web application server port
set webAppServerPort=7179
rem environment override web application server port
if not "%PayrollEnginewebAppPort%" == "" set webAppServerPort=%PayrollEnginewebAppPort%

rem --- start web application server ---
pushd %~dp0PayrollEngine.WebApp\
start dotnet PayrollEngine.WebApp.Server.dll --urls=%webAppServerUrl%:%webAppServerPort%/
popd

rem --- cleanup ---
set webAppServerPort=
set webAppServerUrl=
