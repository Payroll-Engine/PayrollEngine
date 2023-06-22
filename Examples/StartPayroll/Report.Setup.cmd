@echo off
call PayrollConsole TenantDelete StartTenant /trydelete
call PayrollConsole PayrollImport Basic.json
call PayrollConsole PayrollImport Insurance.json
call PayrollConsole PayrollImport Company.json
call PayrollConsole PayrollImport Report.json
rem build payroll results
rem call PayrollConsole PayrunEmployeeTest Basic.Test.et.json
rem call PayrollConsole PayrunEmployeeTest Insurance.Test.et.json
rem call PayrollConsole PayrunEmployeeTest Company.Test.et.json
call PayrollConsole Report StartTenant lucy.smith@foo.com StartRegulation StartReport Report.Parameters.json /pdf
pause
