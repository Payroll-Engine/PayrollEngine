@echo off

REM --- arguments ---
SET TestDeleteNamespace=%NamespacePayroll%
if "%TestDeleteNamespace%"=="" SET TestDeleteNamespace=Namespace

REM --- delete tenant ---
call PayrollConsole TenantDelete %TestDeleteNamespace% /trydelete /wait

REM --- cleanup ---
SET TestDeleteNamespace=
