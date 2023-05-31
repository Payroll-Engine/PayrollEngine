call PayrollConsole TenantDelete ReportTest /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole ReportTest *.rt.json /showall
