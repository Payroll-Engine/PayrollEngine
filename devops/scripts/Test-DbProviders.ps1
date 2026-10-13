<#
.SYNOPSIS
    Runs the Payroll Engine integration tests against SQL Server, MySQL and PostgreSQL.

.DESCRIPTION
    Executes up to six database scenarios and writes a result report:

      SqlServerFull     current Create-Model.sql on an empty test database
      SqlServerUpdate   baseline schema + baseline data, migrated with Update-Model.sql
      MySqlFull         current Create-Model.mysql.sql in a Docker container
      MySqlUpdate       baseline schema + baseline data, migrated with Update-Model.mysql.sql
      PostgresFull      current Create-Model.pg.sql in a Docker container
      PostgresUpdate    baseline schema + baseline data, migrated with Update-Model.pg.sql

    Update scenarios create the baseline schema from the backend release tag (default v1.1.0),
    start the baseline backend and run the examples (Examples\Setup.All.pecmd and Test.All.pecmd)
    to produce existing payrun jobs and results. After the migration the pay date backfill is verified
    (PayrunJob.PayDate = date of PeriodEnd, result PayDate = payrun job PayDate).

    Each scenario then starts the current backend on the scenario database and runs every
    entry of Tests\Test.All.pecmd, Examples\Setup.All.pecmd and Examples\Test.All.pecmd as a
    separate pecmd process.

    Isolation:
      - SQL Server uses a dedicated test database (default PayrollEngine_DbTest), never PayrollEngine
      - MySQL and PostgreSQL run in dedicated containers (pe-dbtest-*) on dedicated ports
      - The backend runs on a dedicated port (default 5199)

.PARAMETER Scenario
    Scenarios to run (default: all six).

.PARAMETER Test
    Wildcard filter on the test folder names, e.g. 'Payrun*' (default: all tests).

.PARAMETER BaselineVersion
    Previous release used for the update scenarios (default: 1.1.0, git tag v1.1.0 of the backend).

.PARAMETER ReposRoot
    Root folder of the repositories (default: three levels above this script).

.PARAMETER WorkDir
    Working folder for the baseline build, generated scripts, logs and reports.

.PARAMETER SqlServer
    SQL Server instance with Windows authentication (default: localhost).

.PARAMETER SqlServerDatabase
    SQL Server test database, dropped and recreated per scenario (default: PayrollEngine_DbTest).

.PARAMETER BackendPort
    HTTP port of the backend under test (default: 5199).

.PARAMETER TenantIsolationLevel
    Backend tenant isolation level (default: Write). The PayrollConsole sends no Auth-Tenant header,
    imports and the regulation share tests require Write.

.PARAMETER TestTimeoutMinutes
    Timeout per test (default: 15).

.PARAMETER SkipBuild
    Skip the Release build of the current backend and PayrollConsole.

.PARAMETER KeepContainers
    Keep the MySQL and PostgreSQL containers after the scenario.

.EXAMPLE
    .\Test-DbProviders.ps1
    Runs all six scenarios.

.EXAMPLE
    .\Test-DbProviders.ps1 -Scenario PostgresUpdate -Test 'Payrun*'
    Dry run of one scenario with a subset of tests.
#>
[CmdletBinding()]
param(
    [ValidateSet('SqlServerFull', 'SqlServerUpdate', 'MySqlFull', 'MySqlUpdate', 'PostgresFull', 'PostgresUpdate')]
    [string[]]$Scenario = @('SqlServerFull', 'SqlServerUpdate', 'MySqlFull', 'MySqlUpdate', 'PostgresFull', 'PostgresUpdate'),
    [string]$Test = '*',
    [string]$BaselineVersion = '1.1.0',
    [string]$ReposRoot,
    [string]$WorkDir = (Join-Path $env:TEMP 'pe-dbtest'),
    [string]$SqlServer = 'localhost',
    [string]$SqlServerDatabase = 'PayrollEngine_DbTest',
    [int]$BackendPort = 5199,
    [ValidateSet('None', 'Consolidation', 'Read', 'Write')]
    [string]$TenantIsolationLevel = 'Write',
    [int]$TestTimeoutMinutes = 15,
    [switch]$SkipBuild,
    [switch]$KeepContainers
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if (-not $ReposRoot) {
    # Windows PowerShell does not provide $PSScriptRoot in parameter defaults
    $ReposRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
}

# --- configuration -----------------------------------------------------------

$MySqlImage = 'mysql:8.0'
$MySqlPassword = 'poc123'
$PostgresImage = 'postgres:17'
$PostgresUser = 'payroll'
$PostgresPassword = 'poc123'

$ScenarioInfo = @{
    SqlServerFull   = @{ Provider = 'SqlServer'; Update = $false }
    SqlServerUpdate = @{ Provider = 'SqlServer'; Update = $true }
    MySqlFull       = @{ Provider = 'MySql'; Update = $false; Container = 'pe-dbtest-mysql-full'; Port = 3316 }
    MySqlUpdate     = @{ Provider = 'MySql'; Update = $true; Container = 'pe-dbtest-mysql-upd'; Port = 3317 }
    PostgresFull    = @{ Provider = 'Postgres'; Update = $false; Container = 'pe-dbtest-pg-full'; Port = 5442 }
    PostgresUpdate  = @{ Provider = 'Postgres'; Update = $true; Container = 'pe-dbtest-pg-upd'; Port = 5443 }
}

$ResultTables = @('WageTypeResult', 'WageTypeCustomResult', 'CollectorResult', 'CollectorCustomResult', 'PayrunResult')

$BackendRepo = Join-Path $ReposRoot 'PayrollEngine.Backend'
$ConsoleRepo = Join-Path $ReposRoot 'PayrollEngine.PayrollConsole'
$MetaRepo = Join-Path $ReposRoot 'PayrollEngine'
$BackendDll = Join-Path $BackendRepo 'Backend.Server\bin\Release\net10.0\PayrollEngine.Backend.Server.dll'
$Pecmd = Join-Path $ConsoleRepo 'PayrollConsole\bin\Release\net10.0\PayrollEngine.PayrollConsole.exe'
$BaselineRoot = Join-Path $WorkDir "baseline-v$BaselineVersion"
$BaselineDll = Join-Path $BaselineRoot 'Backend.Server\bin\Release\net10.0\PayrollEngine.Backend.Server.dll'
$RunDir = Join-Path $WorkDir ('run-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

if ($SqlServerDatabase -eq 'PayrollEngine') {
    throw 'The SQL Server test database must not be the PayrollEngine database.'
}

# --- helpers -----------------------------------------------------------------

function Write-Step([string]$message) {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $message" -ForegroundColor Cyan
}

function Invoke-Native {
    param([string]$FilePath, [string[]]$Arguments, [string]$LogFile, [switch]$PassOutput)
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
    $text = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
    if ($LogFile) {
        Add-Content -Path $LogFile -Value "> $FilePath $($Arguments -join ' ')$([Environment]::NewLine)$text"
    }
    if ($exitCode -ne 0) {
        throw "$(Split-Path $FilePath -Leaf) failed with exit code $exitCode$(if ($LogFile) { " (see $LogFile)" })"
    }
    if ($PassOutput) {
        return $text
    }
}

function Invoke-NativeOutput {
    param([string]$FilePath, [string[]]$Arguments)
    # stdout only, stderr warnings (e.g. password on command line) are ignored
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & $FilePath @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previous
    }
    if ($exitCode -ne 0) {
        throw "$(Split-Path $FilePath -Leaf) $($Arguments -join ' ') failed with exit code $exitCode"
    }
    return (($output | ForEach-Object { "$_" }) -join "`n").Trim()
}

function ConvertTo-NativeArgument([string]$value) {
    # Windows PowerShell (and legacy argument passing) drops embedded double quotes
    $passing = Get-Variable PSNativeCommandArgumentPassing -ValueOnly -ErrorAction SilentlyContinue
    if ($PSVersionTable.PSVersion.Major -lt 7 -or "$passing" -eq 'Legacy') {
        return $value.Replace('"', '\"')
    }
    return $value
}

function Test-PortInUse([int]$port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect('localhost', $port)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Invoke-WithEnvironment([hashtable]$variables, [scriptblock]$action) {
    $saved = @{}
    foreach ($name in $variables.Keys) {
        $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $variables[$name], 'Process')
    }
    try {
        & $action
    }
    finally {
        foreach ($name in $saved.Keys) {
            [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process')
        }
    }
}

# --- build -------------------------------------------------------------------

function Build-Current {
    $log = Join-Path $RunDir 'build.log'
    Write-Step 'Building current backend (Release)'
    Invoke-Native 'dotnet' @('build', (Join-Path $BackendRepo 'Backend.Server\PayrollEngine.Backend.Server.csproj'), '-c', 'Release', '--nologo', '-v', 'q') $log
    Write-Step 'Building current PayrollConsole (Release)'
    Invoke-Native 'dotnet' @('build', (Join-Path $ConsoleRepo 'PayrollConsole\PayrollEngine.PayrollConsole.csproj'), '-c', 'Release', '--nologo', '-v', 'q') $log
}

function Build-Baseline {
    if (Test-Path $BaselineDll) {
        Write-Step "Baseline backend v$BaselineVersion present: $BaselineRoot"
        return
    }
    $log = Join-Path $RunDir 'build-baseline.log'
    Write-Step "Building baseline backend v$BaselineVersion"
    if (Test-Path $BaselineRoot) {
        Remove-Item $BaselineRoot -Recurse -Force
    }
    $zip = Join-Path $WorkDir "backend-v$BaselineVersion.zip"
    Invoke-Native 'git' @('-C', $BackendRepo, 'archive', '--format=zip', '-o', $zip, "v$BaselineVersion") $log
    Expand-Archive -Path $zip -DestinationPath $BaselineRoot -Force
    Remove-Item $zip -Force
    Invoke-Native 'dotnet' @('build', (Join-Path $BaselineRoot 'Backend.Server\PayrollEngine.Backend.Server.csproj'), '-c', 'Release', '--nologo', '-v', 'q') $log
    if (-not (Test-Path $BaselineDll)) {
        throw "Baseline backend build output missing: $BaselineDll"
    }
}

# --- database providers ------------------------------------------------------

function Get-QuotedName([string]$provider, [string]$name) {
    switch ($provider) {
        'SqlServer' { return "[$name]" }
        'MySql' { return "``$name``" }
        'Postgres' { return "`"$name`"" }
    }
}

function Get-ConnectionString($info) {
    switch ($info.Provider) {
        'SqlServer' { return "Server=$SqlServer;Database=$SqlServerDatabase;Integrated Security=SSPI;TrustServerCertificate=True;Connection Timeout=1000" }
        'MySql' { return "Server=localhost;Port=$($info.Port);Database=PayrollEngine;User=root;Password=$MySqlPassword;CharSet=utf8mb4;" }
        'Postgres' { return "Host=localhost;Port=$($info.Port);Database=PayrollEngine;Username=$PostgresUser;Password=$PostgresPassword;" }
    }
}

function New-SqlServerScript([string]$source, [string]$target) {
    # the SQL Server scripts address the database by name
    $script = [IO.File]::ReadAllText($source)
    $script = $script.Replace('[PayrollEngine]', "[$SqlServerDatabase]").Replace("N'PayrollEngine'", "N'$SqlServerDatabase'")
    [IO.File]::WriteAllText($target, $script, (New-Object System.Text.UTF8Encoding $true))
    return $target
}

function New-PostgresInitDir([string]$backendRoot, [string]$target) {
    # same layout as Database\docker-pg\Prepare-Init.cmd
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Copy-Item (Join-Path $backendRoot 'Database\Create-Model.pg.sql') (Join-Path $target '01-Create-Model.pg.sql')
    foreach ($folder in @(@{ Path = 'Functions'; Prefix = '02-' }, @{ Path = 'StoredProcedures'; Prefix = '03-' })) {
        $sourceDir = Join-Path $backendRoot "Persistence\Persistence.Postgres\$($folder.Path)"
        foreach ($file in Get-ChildItem $sourceDir -Filter '*.pg.sql') {
            Copy-Item $file.FullName (Join-Path $target ($folder.Prefix + $file.BaseName + '.pg.sql'))
        }
    }
    return $target
}

function Wait-ContainerHealthy([string]$container, [int]$timeoutSeconds = 600) {
    $deadline = (Get-Date).AddSeconds($timeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $state = Invoke-NativeOutput 'docker' @('inspect', '-f', '{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{end}}', $container)
        $status, $health = $state.Split('|')
        if ($status -ne 'running') {
            throw "Container $container stopped during initialization (status $status), see: docker logs $container"
        }
        if ($health -eq 'healthy') {
            return
        }
        Start-Sleep -Seconds 5
    }
    throw "Container $container not healthy after $timeoutSeconds seconds"
}

function Remove-Container([string]$container) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & docker rm -f -v $container 2>&1 | Out-Null
    $ErrorActionPreference = $previous
}

function Initialize-Database($info, [string]$backendRoot, [string]$scenarioDir) {
    $log = Join-Path $scenarioDir 'database.log'
    switch ($info.Provider) {
        'SqlServer' {
            $drop = "IF DB_ID(N'$SqlServerDatabase') IS NOT NULL BEGIN ALTER DATABASE [$SqlServerDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$SqlServerDatabase]; END"
            Invoke-Native 'sqlcmd' @('-S', $SqlServer, '-E', '-C', '-b', '-d', 'master', '-Q', $drop) $log
            $script = New-SqlServerScript (Join-Path $backendRoot 'Database\Create-Model.sql') (Join-Path $scenarioDir 'Create-Model.sql')
            Invoke-Native 'sqlcmd' @('-S', $SqlServer, '-E', '-C', '-b', '-f', '65001', '-i', $script) $log
        }
        'MySql' {
            Remove-Container $info.Container
            $script = Join-Path $scenarioDir 'Create-Model.mysql.sql'
            Copy-Item (Join-Path $backendRoot 'Database\Create-Model.mysql.sql') $script
            Invoke-Native 'docker' @('run', '-d', '--name', $info.Container,
                '-e', "MYSQL_ROOT_PASSWORD=$MySqlPassword",
                '-p', "$($info.Port):3306",
                '-v', "$($script):/docker-entrypoint-initdb.d/01-Create-Model.mysql.sql:ro",
                '--health-cmd', "mysqladmin ping -h 127.0.0.1 -uroot -p$MySqlPassword",
                '--health-interval', '5s', '--health-retries', '120',
                $MySqlImage) $log
            Wait-ContainerHealthy $info.Container
        }
        'Postgres' {
            Remove-Container $info.Container
            $initDir = New-PostgresInitDir $backendRoot (Join-Path $scenarioDir 'pg-init')
            Invoke-Native 'docker' @('run', '-d', '--name', $info.Container,
                '-e', "POSTGRES_PASSWORD=$PostgresPassword",
                '-e', "POSTGRES_USER=$PostgresUser",
                '-e', 'POSTGRES_DB=PayrollEngine',
                '-e', 'POSTGRES_INITDB_ARGS=--encoding=UTF8 --locale=en_US.UTF-8',
                '-p', "$($info.Port):5432",
                '-v', "$($initDir):/docker-entrypoint-initdb.d:ro",
                '--health-cmd', "pg_isready -h 127.0.0.1 -U $PostgresUser -d PayrollEngine",
                '--health-interval', '5s', '--health-retries', '120',
                $PostgresImage) $log
            Wait-ContainerHealthy $info.Container
        }
    }
}

function Update-Database($info, [string]$scenarioDir) {
    $log = Join-Path $scenarioDir 'database.log'
    switch ($info.Provider) {
        'SqlServer' {
            $script = New-SqlServerScript (Join-Path $BackendRepo 'Database\Update-Model.sql') (Join-Path $scenarioDir 'Update-Model.sql')
            Invoke-Native 'sqlcmd' @('-S', $SqlServer, '-E', '-C', '-b', '-f', '65001', '-i', $script) $log
        }
        'MySql' {
            Invoke-Native 'docker' @('cp', (Join-Path $BackendRepo 'Database\Update-Model.mysql.sql'), "$($info.Container):/tmp/Update-Model.mysql.sql") $log
            Invoke-Native 'docker' @('exec', $info.Container, 'sh', '-c',
                "mysql --comments -uroot -p$MySqlPassword PayrollEngine < /tmp/Update-Model.mysql.sql") $log
        }
        'Postgres' {
            Invoke-Native 'docker' @('cp', (Join-Path $BackendRepo 'Database\Update-Model.pg.sql'), "$($info.Container):/tmp/Update-Model.pg.sql") $log
            Invoke-Native 'docker' @('exec', $info.Container, 'psql', '-v', 'ON_ERROR_STOP=1',
                '-U', $PostgresUser, '-d', 'PayrollEngine', '-f', '/tmp/Update-Model.pg.sql') $log
        }
    }
}

function Invoke-DbScalar($info, [string]$sql) {
    switch ($info.Provider) {
        'SqlServer' {
            $value = Invoke-NativeOutput 'sqlcmd' @('-S', $SqlServer, '-E', '-C', '-b', '-d', $SqlServerDatabase, '-h', '-1', '-W', '-Q', "SET NOCOUNT ON; $sql")
        }
        'MySql' {
            $value = Invoke-NativeOutput 'docker' @('exec', $info.Container, 'mysql', '-uroot', "-p$MySqlPassword", '-N', '-B', 'PayrollEngine', '-e', $sql)
        }
        'Postgres' {
            $value = Invoke-NativeOutput 'docker' @('exec', $info.Container, 'psql', '-U', $PostgresUser, '-d', 'PayrollEngine', '-t', '-A', '-c', (ConvertTo-NativeArgument $sql))
        }
    }
    return [long]($value.Split("`n")[0].Trim())
}

function Get-SchemaVersion($info) {
    $q = { param($name) Get-QuotedName $info.Provider $name }
    $value = Invoke-DbScalar $info "SELECT MAX($(& $q 'MajorVersion') * 10000 + $(& $q 'MinorVersion') * 100 + $(& $q 'SubVersion')) FROM $(& $q 'Version')"
    return '{0}.{1}.{2}' -f [math]::Floor($value / 10000), ([math]::Floor($value / 100) % 100), ($value % 100)
}

function Get-PayrunJobCount($info) {
    return Invoke-DbScalar $info "SELECT COUNT(*) FROM $(Get-QuotedName $info.Provider 'PayrunJob')"
}

function Test-PayDateBackfill($info) {
    $q = { param($name) Get-QuotedName $info.Provider $name }
    $job = & $q 'PayrunJob'
    $findings = @()
    $jobCount = Get-PayrunJobCount $info
    if ($jobCount -eq 0) {
        $findings += 'no payrun jobs'
    }
    $jobMismatch = Invoke-DbScalar $info "SELECT COUNT(*) FROM $job WHERE CAST($(& $q 'PayDate') AS DATE) <> CAST($(& $q 'PeriodEnd') AS DATE)"
    if ($jobMismatch -ne 0) {
        $findings += "PayrunJob: $jobMismatch pay dates differ from the period end date"
    }
    $counts = @()
    foreach ($table in $ResultTables) {
        $resultTable = & $q $table
        $count = Invoke-DbScalar $info "SELECT COUNT(*) FROM $resultTable"
        $mismatch = Invoke-DbScalar $info ("SELECT COUNT(*) FROM $resultTable r INNER JOIN $job j ON j.$(& $q 'Id') = r.$(& $q 'PayrunJobId') " +
            "WHERE r.$(& $q 'PayDate') <> j.$(& $q 'PayDate')")
        if ($mismatch -ne 0) {
            $findings += "$($table): $mismatch pay dates differ from the payrun job"
        }
        $counts += "$table $count"
    }
    if ((Invoke-DbScalar $info "SELECT COUNT(*) FROM $(& $q 'WageTypeResult')") -eq 0) {
        $findings += 'no wage type results'
    }
    return [pscustomobject]@{
        Success  = ($findings.Count -eq 0)
        Summary  = "jobs $jobCount, $($counts -join ', ')"
        Findings = $findings
    }
}

# --- backend -----------------------------------------------------------------

function Start-Backend([string]$dll, $info, [string]$logFile) {
    if (Test-PortInUse $BackendPort) {
        throw "Backend port $BackendPort is in use"
    }
    $variables = @{
        ConnectionStrings__PayrollDatabaseConnection     = (Get-ConnectionString $info)
        PayrollServerConfiguration__DbProvider           = $info.Provider
        PayrollServerConfiguration__TenantIsolationLevel = $TenantIsolationLevel
        ASPNETCORE_URLS                                  = "http://localhost:$BackendPort"
    }
    $process = Invoke-WithEnvironment $variables {
        Start-Process 'dotnet' -ArgumentList "`"$dll`"" -WorkingDirectory (Split-Path $dll) -NoNewWindow -PassThru `
            -RedirectStandardInput $EmptyInput -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err"
    }
    $null = $process.Handle
    $deadline = (Get-Date).AddMinutes(3)
    while ((Get-Date) -lt $deadline) {
        if ($process.HasExited) {
            throw "Backend exited with code $($process.ExitCode) during startup (see $logFile)"
        }
        try {
            $response = Invoke-WebRequest "http://localhost:$BackendPort/api/tenants" -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -lt 500) {
                return $process
            }
        }
        catch {
            $webResponse = $_.Exception.Response
            if ($webResponse -and [int]$webResponse.StatusCode -lt 500) {
                return $process
            }
        }
        Start-Sleep -Seconds 2
    }
    Stop-Backend $process
    throw "Backend not ready after 3 minutes (see $logFile)"
}

function Stop-Backend($process) {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit(30000) | Out-Null
    }
}

# --- tests -------------------------------------------------------------------

function Get-TestEntries([string]$set, [string]$filter) {
    # Setup.All.pecmd (optional) runs before Test.All.pecmd: some tests require the setup data
    $setDir = Join-Path $MetaRepo $set
    $entries = @()
    foreach ($list in @(@{ File = 'Setup.All.pecmd'; Kind = 'setup' }, @{ File = 'Test.All.pecmd'; Kind = 'test' })) {
        $listFile = Join-Path $setDir $list.File
        if (-not (Test-Path $listFile)) {
            continue
        }
        foreach ($line in Get-Content $listFile) {
            $text = $line.Trim()
            if (-not $text) {
                continue
            }
            $skip = $text.StartsWith('#')
            $path = $text.TrimStart('#').Trim()
            $name = ($path -split '[\\/]')[0]
            if ($name -notlike $filter) {
                continue
            }
            $key = if ($list.Kind -eq 'setup') { "$set/$name (setup)" } else { "$set/$name" }
            $entries += [pscustomobject]@{ Set = $set; Name = $name; Kind = $list.Kind; Key = $key; File = (Join-Path $setDir $path); Skip = $skip }
        }
    }
    return $entries
}

function Invoke-TestEntry($entry, [string]$logDir) {
    if ($entry.Skip) {
        return 'skip'
    }
    $log = Join-Path $logDir "$($entry.Set)-$($entry.Name)-$($entry.Kind).log"
    $process = Invoke-WithEnvironment @{ PayrollApiConnection = "BaseUrl=http://localhost;Port=$BackendPort" } {
        Start-Process $Pecmd -ArgumentList "`"$(Split-Path $entry.File -Leaf)`"", '/nowait' `
            -WorkingDirectory (Split-Path $entry.File) -NoNewWindow -PassThru `
            -RedirectStandardInput $EmptyInput -RedirectStandardOutput $log -RedirectStandardError "$log.err"
    }
    $null = $process.Handle
    if (-not $process.WaitForExit($TestTimeoutMinutes * 60000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        return 'timeout'
    }
    if ($process.ExitCode -eq 0) {
        return 'ok'
    }
    return "FAIL ($($process.ExitCode))"
}

function Invoke-TestEntries($entries, [string]$logDir, [string]$label) {
    $entries = @($entries)
    $results = @()
    $index = 0
    foreach ($entry in $entries) {
        $index++
        $outcome = Invoke-TestEntry $entry $logDir
        $color = if ($outcome -eq 'ok') { 'Green' } elseif ($outcome -eq 'skip') { 'DarkGray' } else { 'Red' }
        Write-Host ("  {0} [{1}/{2}] {3}: {4}" -f $label, $index, $entries.Count, $entry.Key, $outcome) -ForegroundColor $color
        $results += [pscustomobject]@{ Key = $entry.Key; Outcome = $outcome }
    }
    return $results
}

# --- scenario ----------------------------------------------------------------

function Invoke-Scenario([string]$name) {
    $info = $ScenarioInfo[$name]
    $scenarioDir = Join-Path $RunDir $name
    New-Item -ItemType Directory -Path $scenarioDir -Force | Out-Null
    $result = [pscustomobject]@{
        Scenario = $name
        Schema   = '-'
        Seed     = '-'
        Backfill = '-'
        Passed   = 0
        Failed   = 0
        Skipped  = 0
        Duration = ''
        Error    = ''
        Tests    = @()
        Findings = @()
    }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $backend = $null
    try {
        if ($info.Update) {
            Write-Step "$($name): baseline schema v$BaselineVersion"
            Initialize-Database $info $BaselineRoot $scenarioDir

            Write-Step "$($name): baseline data (examples on backend v$BaselineVersion)"
            $backend = Start-Backend $BaselineDll $info (Join-Path $scenarioDir 'backend-baseline.log')
            $seed = @(Invoke-TestEntries (Get-TestEntries 'Examples' '*') $scenarioDir 'seed')
            Stop-Backend $backend
            $backend = $null
            $seedOk = @($seed | Where-Object { $_.Outcome -eq 'ok' }).Count
            $result.Seed = "$seedOk/$(@($seed | Where-Object { $_.Outcome -ne 'skip' }).Count), jobs $(Get-PayrunJobCount $info)"

            Write-Step "$($name): migration"
            Update-Database $info $scenarioDir

            $backfill = Test-PayDateBackfill $info
            $result.Backfill = if ($backfill.Success) { 'ok' } else { 'FAIL' }
            $result.Findings = @($backfill.Summary) + @($backfill.Findings)
        }
        else {
            Write-Step "$($name): create schema"
            Initialize-Database $info $BackendRepo $scenarioDir
        }
        $result.Schema = Get-SchemaVersion $info

        Write-Step "$($name): tests on current backend (schema $($result.Schema))"
        $backend = Start-Backend $BackendDll $info (Join-Path $scenarioDir 'backend.log')
        $entries = @(Get-TestEntries 'Tests' $Test) + @(Get-TestEntries 'Examples' $Test)
        $result.Tests = @(Invoke-TestEntries $entries $scenarioDir 'test')
        $result.Passed = @($result.Tests | Where-Object { $_.Outcome -eq 'ok' }).Count
        $result.Skipped = @($result.Tests | Where-Object { $_.Outcome -eq 'skip' }).Count
        $result.Failed = $result.Tests.Count - $result.Passed - $result.Skipped
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Host "  $($name): $($result.Error)" -ForegroundColor Red
    }
    finally {
        Stop-Backend $backend
        if ($info.ContainsKey('Container') -and -not $KeepContainers) {
            Remove-Container $info.Container
        }
        $result.Duration = '{0:hh\:mm\:ss}' -f $watch.Elapsed
    }
    return $result
}

function Test-ScenarioSuccess($result) {
    return (-not $result.Error) -and $result.Failed -eq 0 -and $result.Backfill -ne 'FAIL'
}

# --- report ------------------------------------------------------------------

function Write-Report($results) {
    $lines = @(
        '# Database Provider Test Report',
        '',
        "- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
        "- Backend: $BackendDll",
        "- Baseline: v$BaselineVersion",
        "- Test filter: $Test",
        '',
        '| Scenario | Result | Schema | Baseline data | Backfill | Passed | Failed | Skipped | Duration |',
        '|:--|:--|:--|:--|:--|--:|--:|--:|:--|'
    )
    foreach ($r in $results) {
        $state = if (Test-ScenarioSuccess $r) { 'ok' } else { 'FAIL' }
        $lines += "| $($r.Scenario) | $state | $($r.Schema) | $($r.Seed) | $($r.Backfill) | $($r.Passed) | $($r.Failed) | $($r.Skipped) | $($r.Duration) |"
    }

    $keys = @($results | ForEach-Object { $_.Tests } | ForEach-Object { $_.Key } | Select-Object -Unique)
    if ($keys.Count -gt 0) {
        $lines += '', '## Tests', ''
        $lines += '| Test | ' + (($results | ForEach-Object { $_.Scenario }) -join ' | ') + ' |'
        $lines += '|:--|' + (($results | ForEach-Object { ':--' }) -join '|') + '|'
        foreach ($key in $keys) {
            $cells = foreach ($r in $results) {
                $match = @($r.Tests | Where-Object { $_.Key -eq $key })
                if ($match.Count -gt 0) { $match[0].Outcome } else { '-' }
            }
            $lines += "| $key | $($cells -join ' | ') |"
        }
    }

    $details = @($results | Where-Object { $_.Error -or @($_.Findings).Count -gt 0 })
    if ($details.Count -gt 0) {
        $lines += '', '## Details', ''
        foreach ($r in $details) {
            $lines += "### $($r.Scenario)", ''
            if ($r.Error) {
                $lines += "- Error: $($r.Error)"
            }
            foreach ($finding in $r.Findings) {
                $lines += "- Backfill: $finding"
            }
            $lines += ''
        }
    }
    $lines += '', "Logs: $RunDir"

    $reportFile = Join-Path $RunDir 'Report.md'
    Set-Content -Path $reportFile -Value $lines -Encoding UTF8
    return $reportFile
}

# --- main --------------------------------------------------------------------

New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
Write-Step "Run folder: $RunDir"

# empty standard input: a failing pecmd command must not wait for a key press
$EmptyInput = Join-Path $RunDir 'empty-input.txt'
Set-Content -Path $EmptyInput -Value $null

$needsDocker = @($Scenario | Where-Object { $ScenarioInfo[$_].ContainsKey('Container') }).Count -gt 0
if ($needsDocker) {
    Invoke-Native 'docker' @('info', '--format', '{{.ServerVersion}}') (Join-Path $RunDir 'docker.log')
}
if (@($Scenario | Where-Object { $ScenarioInfo[$_].Provider -eq 'SqlServer' }).Count -gt 0) {
    Invoke-Native 'sqlcmd' @('-S', $SqlServer, '-E', '-C', '-b', '-Q', 'SELECT @@VERSION') (Join-Path $RunDir 'sqlserver.log')
}

if (-not $SkipBuild) {
    Build-Current
}
foreach ($file in @($BackendDll, $Pecmd)) {
    if (-not (Test-Path $file)) {
        throw "Missing build output: $file"
    }
}
if (@($Scenario | Where-Object { $ScenarioInfo[$_].Update }).Count -gt 0) {
    Build-Baseline
}

$results = @()
foreach ($name in $Scenario) {
    $results += Invoke-Scenario $name
}

$report = Write-Report $results
Write-Host ''
foreach ($r in $results) {
    $success = Test-ScenarioSuccess $r
    $text = "{0,-16} {1,-5} schema {2,-6} passed {3,3}  failed {4,3}  backfill {5}" -f $r.Scenario, $(if ($success) { 'ok' } else { 'FAIL' }), $r.Schema, $r.Passed, $r.Failed, $r.Backfill
    Write-Host $text -ForegroundColor $(if ($success) { 'Green' } else { 'Red' })
}
Write-Host ''
Write-Step "Report: $report"

if (@($results | Where-Object { -not (Test-ScenarioSuccess $_) }).Count -gt 0) {
    exit 1
}
exit 0
