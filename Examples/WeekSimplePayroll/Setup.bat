call PayrollConsole TenantDelete WeekSimplePayroll /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole PayrollImport Payroll.Values.json
call PayrollConsole PayrollImport Payroll.Jobs.json
call PayrollConsole PayrollResults WeekSimplePayroll 1
pause
