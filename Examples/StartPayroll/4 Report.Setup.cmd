@echo off
call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrollImport Insurance.json
call PayrollConsole PayrollImport Company.json
call PayrollConsole PayrollImport Report.json
rem build payroll results
call PayrollConsole PayrunEmployeeTest Company.Test.et.json
call PayrollConsole Report tenant:StartTenant user:lucy.smith@foo.com regulation:StartRegulation report:StartReport parameterFile:Report.Parameters.json culture:en /pdf /shellopen
