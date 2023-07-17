@echo off
rem ================= environment settings setup start =================
rem PayrollEngineDatabase: database connections string
set ConnectionString=server=localhost; Initial Catalog=PayrollEngine; Integrated Security=SSPI; Connection Timeout=1000; TrustServerCertificate=true

rem PayrollEngineBackendUrl: backend backend server uls
set BackendUrl=https://localhost

rem PayrollEngineBackendPort: backend backend server port
set BackendPort=44354

rem PayrollEngineWebAppUrl: web application server url
set WebAppUrl=https://localhost

rem PayrollEngineWebAppPort: web application server port
set WebAppPort=7179
rem ================= environment settings setup end =================

echo Setup Payroll Engine Environment...

rem --- Database connection string ---
rem current process
set PayrollEngineDatabase=%ConnectionString%
rem future processes
setx PayrollEngineDatabase "%ConnectionString%" > nul
set ConnectionString=

rem --- Backend Server url ---
rem current process
set PayrollEngineBackendUrl=%BackendUrl%
rem future processes
setx PayrollEngineBackendUrl "%BackendUrl%" > nul
set BackendUrl=

rem --- Backend Server port ---
rem current process
set PayrollEngineBackendPort=%BackendPort%
rem future processes
setx PayrollEngineBackendPort "%BackendPort%" > nul
set BackendPort=

rem --- Web Application Server url ---
rem current process
set PayrollEngineWebAppUrl=%WebAppUrl%
rem future processes
setx PayrollEngineWebAppUrl "%WebAppUrl%" > nul
set WebAppUrl=

rem --- Web Application Server port ---
rem current process
set PayrollEngineWebAppPort=%WebAppPort%
rem future processes
setx PayrollEngineWebAppPort "%WebAppPort%" > nul
set WebAppPort=
