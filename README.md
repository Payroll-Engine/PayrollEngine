<span style="font-size: 3.5em">Payroll Engine</span><br />
<pspan>Open Global Payroll Engine</span><br /><br />

# Introduction
Die Payroll Engine ist ein Backend-Dienst zur Entwicklung und Nutzung von branchen- und landesübergreifenden Lohndiensten. Sie ist ein neutraler Lohnrechner, welcher von *Regulierungen* betrieben wird. Die Regulierung ist Bestandteil der Lohndefinition und steuert den Lohnprozess. Die Engine bietet technisch versierten Payrollspezialisten die Möglichkeit, Lohnlösungen autonom zu entwickeln.

**Automatisierung Lohnprozess**<br/>
Im Fokus der Lösung steht die Automatisierung von Spezialfällen im Lohnprozess. Dank einem neuartigen Ansatz werden die lohnrelevanten Informationen vom HR/Mitarbeiter zum Zeitpunkt des Falles bestimmt. Änderungen können rückwirkendend sein und werden in der Zukunft berücksichtigt. 

Daraus resultieren folgende Vorteile:
- Die Geschäftsdaten sind zu jedem Abfragezeitpunkt gültig
- Die Geschäftsdaten können aus der Vergangenheit (was galt damals) und Zukunft (was wird zukünftig gelten) betrachtet werden
- Lohnläufe sind jederzeit möglich

**Engine Features**<br/>
The Payroll Engine offers the following features:

| Feature                      | Description                               |
|--|--|
| Multi-Country                | Execute payroll in different countries    |
| Multi-Tenancy                | Host multiple tenants                     |
| Company Divisions            | Different payrolls within a company       |
| Multi-Payrun                 | Run multiple payruns in a payroll period  |
| Forecasts                    | Future payroll simulation                 |
| Case driven model            | Dynamic input workflow                    |
| Time values                  | View and enter past/future data           |
| Case Actions                 | No-Code case control                      |
| [Regulations](Regulation.md) | Component based payroll layers            |
| Automated Testing            | Payroll Tests over multiple periods       |
| Embedded payroll             | Integration to your service through REST  |
| Scripting API                | Programming the payroll runtime behaviour |
| Open Source                  | Free for private and commercial use       |
<br/>

Read the [White Paper](Documents/PayrolEngineWhitePaper.pdf) for deeper insights.

**About this project**<br/>

*Die Idee der Payroll Engine enstand aus einem meiner Beratungsmandate, Anfangs 2018. Nach mehreren Entwicklungsphasen, möchte ich mit dieser Code-Offenlegung die Praxistauglichkeit des Projektes nachweisen und das Entwicklungsteam ausbauen. Aktuell befindet sich die Engine in der Prerelase-Phase. Ich hoffe auf reges Feedbacks, um in wenigen Monaten die proktionsfähige Engine freizugeben. Du kannst das Projekt als aktives Teammitglied oder mit [Spenden] unterstützen.<br /><br />Viel Spass mit der Payroll Engine - Jani Giannoudis*

<br/>

# Application scenarios
The Payroll Engine distinguishes between two application scenarios:
|                                | Business developer                     |  Technical business developer         |
|--|--|--|
| Methodology                    | No-Code                                | Low-Code                              |
| User skills                    |  - Payroll know-how<br />- Basic OO principles like [Inheritance](https://en.wikipedia.org/wiki/Inheritance_(object-oriented_programming))<br />- Function scripting (Excel like)<br />| - Using [JSON](https://de.wikipedia.org/wiki/JavaScript_Object_Notation)<br /> - Intermediate [C#](https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/) knowledge<br />- [GitHub](https://github.com/) and [NuGet](https://www.nuget.org/) Management |
| Building Reports <sup>1)</sup> | FastReport Designer ([Community Edition](https://fastreports.github.io/FastReport.Documentation/FastReportDesignerCommunityEdition.html)) | Microsoft [ADO.NET DataSets](https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/ado-net-datasets)   |
| Engine tool                    | [Payroll Engine Web Application](https://github.com/Payroll-Engine/PayrollEngine.WebApp) | [Payroll Engine Console Application](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole)     |
| Development tool               | *not required*                        | - Visual Studio ([Windows](https://visualstudio.microsoft.com/en/vs/community/), [MacOS](https://visualstudio.microsoft.com/vs/mac/))<br />- Visual Studio Code ([Windows/Linux/MacOS](https://code.visualstudio.com/))  |
<br/>

<sup>1)</sup> Requires Low-Code development<br/>
<br/>

# Using the Engine
The Payroll Engine is a [.NET](https://dotnet.microsoft.com/en-us/download/dotnet/7.0) based application and can be operated on Windows, Linux or MacOS. An SQL server database is required to store the backed data. 

Three steps are necessary to use the Payroll Engine:
1. [Setup](Documents/Setup.md) the Payroll Engine system
2. Build a payroll [Regulation](Documents/RegulationBuild.md)
3. Manage the employee [Paroll](Documents/Payroll.md)

<br/>

# Resources
| Resource                                                                               | Content                                           | Type           |
|--|--|--|
| [Payroll Engine GitHub Repositories](Documents/Repositories.md)                               | Overview of the Payroll Engine repositories       | Document       |
| [REST API Endpoints](Documents/PayrollRestServicesEndpoints.pdf)                       | Overview of the REST endpoints                    | Document       |
| [Payroll Examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples) | Payroll examples                                  | JSON/C# files  |
| [Payroll Tests](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Tests)       | Automated Payroll Tests                           | JSON/C# files  |
| [Client Tutorials](https://github.com/Payroll-Engine/PayrollEngine.Client.Tutorials)   | Tutorials for .NET client applications            | C# Repository  |
| [Payroll Engine White Paper](Documents/PayrolEngineWhitePaper.pdf)                     | Technical system description                      | Document       |
| [Software Enginnering](Documents/SoftwareEngineering.md)                               | Community Guidelines                              | Document       |
<br/>
