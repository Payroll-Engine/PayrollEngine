@echo off
call PayrollConsole TenantDelete ExtendedTenant /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrunEmployeeTest Test.et.json /showall /wait

