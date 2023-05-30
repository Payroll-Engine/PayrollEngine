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

| Feature                      |                                           |
|--|--|
| Multi-Country                | Execute payroll in different countries    |
| Multi-Tenancy                | Host multiple tenants                     |
| Company Divisions            | Different payrolls within a company       |
| Multi-Payrun                 | Run multiple payruns in a payroll period  |
| Forecasts                    | Future payroll simulation                 |
| Case driven model            | Dynamic input workflow                    |
| Time values                  | View and enter past/future data           |
| Case Actions                 | User input control with No-Code           |
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

# Using the Engine
The Payroll Engine is a [.NET](https://dotnet.microsoft.com/en-us/download/dotnet/7.0) based application and can be operated on Windows, Linux or MacOS. An SQL server database is required to store the backed data. 

Follow these steps to use the Payroll Engine:
1. [Setup](Documents/Setup.md) the Payroll Engine
2. [Onboard](Documents/Onboarding.md) your company
3. Build your own [Regulation](Documents/RegulationBuild.md)
4. Processing the employee [Payroll](Documents/Payroll.md)

<br/>

# Resources
| Resource                                                                               |                                                   | Type           |
|--|--|--|
| [Payroll Engine GitHub Repositories](Documents/Repositories.md)                        | Overview of the Payroll Engine repositories       | Document       |
| [REST API Endpoints](Documents/PayrollRestServicesEndpoints.pdf)                       | Overview of the REST endpoints                    | Document       |
| [Payroll Examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples) | Payroll examples                                  | JSON/C# files  |
| [Payroll Tests](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Tests)       | Automated Payroll Tests                           | JSON/C# files  |
| [Client Tutorials](https://github.com/Payroll-Engine/PayrollEngine.Client.Tutorials)   | Tutorials for .NET client applications            | C# Repository  |
| [Payroll Engine White Paper](Documents/PayrolEngineWhitePaper.pdf)                     | Technical system description                      | Document       |
| [Software Enginnering](Documents/SoftwareEngineering.md)                               | Community Guidelines                              | Document       |
<br/>
