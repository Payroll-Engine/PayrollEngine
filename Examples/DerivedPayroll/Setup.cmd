call PayrollConsole TenantDelete DerivedPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Jobs.json
rem call PayrollConsole PayrollResults DerivedPayroll 1
rem pause
