@echo off

REM --- arguments ---
SET TestImportNamespace=%NamespacePayroll%
if "%TestImportNamespace%"=="" SET TestImportNamespace=Namespace

REM --- delete tenant ---
call PayrollConsole PayrollImport Payroll.json %TestImportNamespace% /wait

REM --- cleanup ---
SET TestImportNamespace=
