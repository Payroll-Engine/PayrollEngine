@echo off

rem --- backend url ---
rem default backend url
set backendUrl=https://localhost
rem environment override backend url
if not "%PayrollEnginebackendUrl%" == "" set backendUrl=%PayrollEnginebackendUrl%

rem --- backend port ---
rem default backend port
set backendPort=44354
rem environment override backend port
if not "%PayrollEnginebackendPort%" == "" set backendPort=%PayrollEnginebackendPort%

rem --- start swagger ---
start "" %backendUrl%:%backendPort%/

rem --- cleanup ---
set backendPort=
set backendUrl=
