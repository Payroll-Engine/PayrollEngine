@echo off

rem --- web app url ---
set webappurl=https://localhost
if not "%PayrollEnginewebappUrl%" == "" set webappurl=%PayrollEnginewebappUrl%

rem --- web app port ---
set webappport=7179
if not "%PayrollEnginewebappPort%" == "" set webappport=%PayrollEnginewebappPort%

rem --- start web app ---
start "" %webappurl%:%webappport%/

rem --- cleanup ---
set webappport=
set webappurl=
