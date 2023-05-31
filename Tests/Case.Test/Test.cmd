call PayrollConsole TenantDelete CaseTest /trydelete
call PayrollConsole PayrollImport Payroll.json
call PayrollConsole CaseTest *.ct.json
