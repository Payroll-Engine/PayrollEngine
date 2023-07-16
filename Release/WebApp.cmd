@echo off

rem --- web app url ---
rem default web application url
set webAppUrl=https://localhost
rem environment override web application url
if not "%PayrollEnginewebAppUrl%" == "" set webAppUrl=%PayrollEnginewebAppUrl%

rem --- web app port ---
rem default web application port
set webAppPort=7179
rem environment override web application port
if not "%PayrollEnginewebAppPort%" == "" set webAppPort=%PayrollEnginewebAppPort%

rem --- start web application ---
start "" %webAppUrl%:%webAppPort%/

rem --- cleanup ---
set webAppPort=
set webAppUrl=
