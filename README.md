<span style="font-size: 50px">Payroll Engine</span><br />
<pspan>Open Global Payroll Engine</span><br /><br />

# Introduction
Die Payroll Engine ist ein Backend-Dienst zur Entwicklung und Nutzung von branchen- und landesübergreifenden Lohndiensten. Sie ist ein neutraler Lohnrechner, welcher von *Regulierungen* betrieben wird. Die Regulierung ist Bestandteil der Lohndefinition und steuert den Lohnprozess. Die Engine bietet technisch versierten Payrollspezialisten die Möglichkeit, Lohnlösungen autonom zu entwickeln.

**Automatisierung Lohnprozess**<br/>
Im Fokus der Lösung steht die Automatisierung von Spezialfällen im Lohnprozess. Dank einem neuartigen Ansatz werden die lohnrelevanten Informationen vom HR/Mitarbeiter zum Zeitpunkt des Falles bestimmt. Änderungen können rückwirkendend sein und werden in der Zukunft berücksichtigt. 

Daraus resultieren folgende Vorteile:
- Die Geschäftsdaten sind zu jedem Abfragezeitpunkt vollständig und gültig
- Die Geschäftsdaten können aus der Vergangenheit (was galt damals) und Zukunft (was wird zukünftig gelten) betrachtet werden
- Dank Lohnläufe sind jederzeit möglich, verzögerte Abklärungen entfallen

**Engine Features**<br/>
The Payroll Engine offers the following features:

| Feature                      |                                                             |
|--|--|
| Multi-Country                | Manage companies with payroll in different countries        |
| Multi-Tenancy                | Manage multiple companies including regulatory sharing      |
| Company Divisions            | Use different payrolls within a company                     |
| Multi-Payrun                 | Run multiple payruns in a payroll period                    |
| Forecasts                    | Future payroll simulation                                   |
| [Regulations](Regulation.md) | Component based payroll layers                              |
| Time values                  | View and enter past/future company data                     |
| Case driven model            | Dynamic input workflow                                      |
| Case Actions                 | User input control with No-Code                             |
| Automated Testing            | Payroll Tests over multiple periods                         |
| Embedded Payroll             | Integration to your service through REST API                |
| Scripting API                | Programming the payroll runtime behaviour                   |
| Integration SDK              | Integration components for data exchange                    |
| Open Source                  | Free for private and commercial use                         |
<br/>

Please read the [White Paper](Documents/PayrolEngineWhitePaper.pdf) for deeper insights.

**Security**<br/>
Die als Hintergrunddienst fungierende Payroll Engine hat keine authentication and authorization. Die Web Applikation hat ein User-Login mit einem Passwort.

> *Die Payroll Engine sollte nicht im öffentlichen Internet eingesetzt werden*

Auf Datenbankebene verhindert die leichtgewichte ORM-Komponente [Dapper]() SQL Injections.

<br/>

**About this project**<br/>

Die Idee der Payroll Engine enstand aus einem meiner Beratungsmandate, Anfangs 2018. Nach mehreren Entwicklungsphasen, möchte ich mit dieser Code-Offenlegung die Praxistauglichkeit des Projektes nachweisen und das Entwicklungsteam ausbauen. Aktuell befindet sich die Engine in der Prerelase-Phase. Ich hoffe auf reges Feedbacks, um in wenigen Monaten die proktionsfähige Engine freizugeben. Du kannst das Projekt als aktives Teammitglied oder mit [Spenden] unterstützen.<br /><br />*Viel Spass mit der Payroll Engine - Jani Giannoudis*

<br/>

# Prerequisites
The Payroll Engine is a [.NET](https://dotnet.microsoft.com/en-us/download/dotnet/7.0) based application and can be operated on
- Windows
- Linux
- MacOS

The backend server requires an SQL-Server database. Please read the [Installation](Documents/Setup.md) document for more details.

<br/>

# Using the Engine
Follow these steps to use the Payroll Engine:
1. *[Install](Documents/Setup.md)* the Payroll Engine
2. *[Setup](Documents/CompanySetup.md)* your Company
3. *Build* your Regulation by example:
    - Introduction example with a simple [Company Regulation](Documents/CompanyRegulation.md)
    - Featured example including multiple Regulations:
        - [Country Regulation](Documents/CountryRegulation.md)
        - [Contract Regulation](Documents/ContractRegulation.md)
        - [Customized Company Regulation](Documents/CustomRegulation.md)
4. *[Process](Documents/Payroll.md)* the employee Payroll including:
    - HR/Employee: Enter company and employee Cases
    - Payroll Management: Execute payruns
    - All: Report company, employee and payroll data

<br/>

# Integration
- Link externel identifications to payroll objects like Tenant, Division, User and Employee
- Store custom data to payroll object attributes, with OData query support
- Store financial accounting infortion as payrun result
- Data Reports for data exchange

Implementierung:
- Basic REST API integration
- .NET Client Services integration
- Webhooks


# Resources
| Resource                                                                               |                                                   | Type             |
|--|--|--|
| [Payroll Engine GitHub Repositories](Documents/Repositories.md)                        | Overview of the Payroll Engine repositories       | Document         |
| [REST API Endpoints](Documents/PayrollRestServicesEndpoints.pdf)                       | Overview of the REST endpoints                    | Document         |
| [Payroll Examples](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Examples) | Payroll examples                                  | JSON/C# payrolls |
| [Payroll Tests](https://github.com/Payroll-Engine/PayrollEngine/tree/main/Tests)       | Automated Payroll Tests                           | JSON/C# payrolls |
| [Client Tutorials](https://github.com/Payroll-Engine/PayrollEngine.Client.Tutorials)   | Tutorials for .NET client applications            | C# Repository    |
| [Payroll Engine White Paper](Documents/PayrolEngineWhitePaper.pdf)                     | Technical system description                      | Document         |
| [Software Enginnering](Documents/SoftwareEngineering.md)                               | Community Guidelines                              | Document         |
<br/>
