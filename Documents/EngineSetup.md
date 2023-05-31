<h1>Payroll Engine Setup</h1>

The following steps describe the installation of the Payroll Engine on the local computer.
The last step *Start Backend Service* is also necessary during operation.

<br />

## 1 System Rquirements
The following software components are required to operate the Payroll Engine:
- Operating system: Windows, Linux or MacOS
- Microsoft [.NET 7](https://dotnet.microsoft.com/en-us/download/dotnet/7.0)
- Database: Microsoft SQL Server ([Express](https://www.microsoft.com/en-us/download/details.aspx?id=104781))

<br />

## 2 Clone Repositories
The following [system repositories](Repositories.md) are to be cloned locally:
| Repository                          | Content                     | URL |
|--|--|--|
| *PayrollEngine*                     | Main repository             | https://github.com/Payroll-Engine/PayrollEngine.git |
| *PayrollEngine.Core*                | Core payroll objects        | https://github.com/Payroll-Engine/PayrollEngine.Core.git |
| *PayrollEngine.Serilog*             | System logger               | https://github.com/Payroll-Engine/PayrollEngine.Serilog.git |
| *PayrollEngine.Document*            | Document/Report generation  | https://github.com/Payroll-Engine/PayrollEngine.Document.git |
| *PayrollEngine.Client.Core*         | Client core payroll objects | https://github.com/Payroll-Engine/PayrollEngine.Client.Core.git |
| *PayrollEngine.Test*                | Client test library         | https://github.com/Payroll-Engine/PayrollEngine.Client.Test.git |
| *PayrollEngine.Client.Scripting*    | Client scripting            | https://github.com/Payroll-Engine/PayrollEngine.Client.Scripting.git |
| *PayrollEngine.Client.Services*     | Main client services        | https://github.com/Payroll-Engine/PayrollEngine.Client.Services.git |
| *PayrollEngine.Backend*             | Backend server              | https://github.com/Payroll-Engine/PayrollEngine.Backend.git |
| *PayrollEngine.PayrollConsole*      | Console application         | https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole.git |
| *PayrollEngine.WebApp*              | Web application             | https://github.com/Payroll-Engine/PayrollEngine.WebApp.git |
<br/>

> Local folder example:<br />Root folder: ***D:\PayrollEngine***<br />Main repo: ***D:\PayrollEngine\PayrollEngine***<br />...

<br /><br />

## 3 Setup System Environment
### Windows
1.	Open the Windows *Control Panel*
2.	Start *System > Edit environment variables for your account*
3.	Fromn the group *User variables for..*
    - Existing: select existing Variable *Path* and start *Edit*
    - New: start *New..* and add the Variable *Path*
4.	Add environment variable withe the *\Commnands* folder of the backend repository<br />

    > Example: ***D:\PayrollEngine\PayrollEngine\Commands***

*ToDo: Linux and MacOS instructions*

<br />

## 4 Setup Database
The tools to setup the Payroll Engine database located in the ***\Database\\{Version}*** directory within the [Payroll Engine Backend Repository].

| Source                   | Commands        |
|--|--|
|*localhost*| - Command line ***DatabaseSetup_{Version}.cmd*** - or -<br />- T-SQL script ***PayrollEngine_DatabaseSetup_{Version}.sql*** in SSMS |
|*custom server*| - T-SQL script ***PayrollEngine_ModelSetup_{Version}.sql*** in SSMS |
<br />

The default installation creates the database *PayrollEngine* using integrated security and the *SQL_Latin1_General_CP1_CS_AS* collation. If another database connection is used, the backend server configuration *appsettings.json* has to be adjusted:
```json
"ConnectionStrings": {
    "PayrollEngineDatabase": "server=localhost; database=PayrollEngine; Integrated Security=SSPI; Connection Timeout=1000"
},
```
> It is recommended to save the backend settings within your local [User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets).

<br />

## 5 Build Applications
The command file ***PayrollEngine\Commands\Setup.cmd*** is used to build the components and applications of the Payroll Engine.
<br />
The setup generates NuGets in the ***PayrollEngine\Packages*** folder and application binaries in the ***PayrollEngine\Bin*** folder.

> It is recommended to register the folder ***PayrollEngine\Packages*** in Visual Studio as a [NuGet Package Source](https://learn.microsoft.com/en-us/nuget/consume-packages/install-use-packages-visual-studio).

<br />

## 6 Start Backend Server
The backend server is started with the command 
```
PayrollEngine\Commands\Backend.Server.cmd
```
and a console window with the server log appears. With the command
```
PayrollEngine\Commands\Backend.Swagger.cmd
```
the Payroll Engine REST endpoints appear in the Swagger browser window.

> Im Kommandomodus läuft das Backend auf dem [Kestrel](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel) web server. Im Gegensatz dazu verwendet Visual Studio [IIS Express](https://learn.microsoft.com/en-us/iis/extensions/introduction-to-iis-express/iis-express-overview).

<br />

## 7 Backend Tests
The command ***PayrollEngine\Commands\Test.Payruns.cmd*** runs several engine tests. The tests are successful when the console window closes automatically.

<br />

*Congrats, you are ready to build regulations :=)*

<br />

## Next steps
The next steps are:
- [Introduction to the Payroll Engine](PayrolEngineWhitePaper.pdf) (white paper)
- [Explore examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples)
- [Build a regulation](RegulationBuild.md)

