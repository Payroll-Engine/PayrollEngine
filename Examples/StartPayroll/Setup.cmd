@echo off
call PayrollConsole TenantDelete StartPayroll /trydelete
call PayrollConsole PayrollImport Payroll.Company.json
call PayrollConsole PayrollImport Payroll.Regulation.Single.json
call PayrollConsole PayrollImport Payroll.Regulation.Distributed.json
call TestAll
