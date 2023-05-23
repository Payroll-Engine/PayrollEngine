call PayrollConsole TenantDelete DerivedPayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json /noupdate
call PayrollConsole PayrollImport Payroll.Jobs.json /noupdate
rem call PayrollConsole PayrollResults DerivedPayroll 1
rem pause
