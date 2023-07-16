@echo off

rem --- backend url ---
set backendurl=https://localhost
if not "%PayrollEngineBackendUrl%" == "" set backendurl=%PayrollEngineBackendUrl%

rem --- backend port ---
set backendport=44354
if not "%PayrollEngineBackendPort%" == "" set backendport=%PayrollEngineBackendPort%

rem --- start swagger ---
set backendport=44354
start "" %backendurl%:%backendport%/

rem --- cleanup ---
set backendport=
set backendurl=
