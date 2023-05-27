<span style="font-size: 60px">Payroll Engine</span><br />
<pspan>Open Global Payroll Engine</span><br /><br />

# 1 Introduction
Die Payroll Engine ist Backend-Dienst zur Entwicklung individueller Lohnlösungen für skalierbare und landesübergreifende Lohndienste. Die Engine fungiert als neutraler Lohnrechner, welcher durch Regulierung gesteuert wird.

**Automatisierung Lohnprozess**<br/>
Im Fokus der Lösung steht die Automatisierung von Spezialfällen in der Lohnberechnung. Dank einem neuartigen Ansatz werden die lohnrelevanten Informationen vom HR/Mitarbeiter zum Zeitpunkt des Falles bestimmt. Änderungen können rückwirkendend sein und werden in der Zukunft berücksichtigt. 

Daraus resultieren folgende Vorteile:
- Die Geschäftsdaten sind zu jedem Abfragezeitpunkt gültig
- Die Geschäftsdaten können aus der Vergangenheit (was galt damals) und Zukunft (was gilt zukünftig) betrachtet werden
- Lohnläufe sind jederzeit möglich

| Feature                      | Description                               |
|--|--|
| Multi-Country                | Supports Payroll for different countries  |
| Multi-Tenancy                | Host multiple tenants                     |
| Company Divisions            | Different payrolls within a company       |
| Multi-Payrun                 | Run multiple payruns in a wage period     |
| Forecasts                    | Future Payroll simulation                 |
| Case driven model            | Dynamic input workflow                    |
| Time values                  | View and enter past/future data           |
| Case Actions                 | No-Code functions                         |
| [Regulations](Regulation.md) | Komponentenbasierte Payrollschichten      |
| Automated Testing            | Payroll Tests over multiple periods       |
| Scripting API                | Programming the payroll runtime behaviour |
| Open Source                  | Free for private and commercial use       |


Read the [White Paper](Documents/PayrolEnginelWhitePaper_de.pdf) for deeper insights.

**About this project**<br/>
Die Idee der Payroll Engine enstand aus einem Beratungsmandat Anfangs 2018. Nach mehreren Enticklungsphasen bietet diese Code-Offenlegung die kostenlose Enticklung von Lohnlösungen. Aktuell befindet sich die Engine in der Preview-Phase. Nach Einbezug des Preview-Feedbacks ist die produktive Version in wenigen Monaten zu erwarten.

Das Projekt kannst du entweder als neues Teammitglied oder mit [Spenden] unterstützen. Viel Spass mit der Payroll Engine - Jani Giannoudis.

<br/>

# 2 Setup Payroll Engine
The Payroll Engine runs on Windows, Linux or MacOS. The [Setup Page](Documents/Setup.md) page describes the installation steps.

<br/>

# 3 Usage
Folgende Anwendungsszenarien werden untestützt:
- [Entiwcklung von Regulierungen](Documents/RegulationBuild.md)
- [Integration der REST API](Documents/Integration.md)
- [.NET Client Entwicklung](Documents/DotNetClients.md)

<br/>

# 4 Ressources
| Resource                                                                  | Content                                   | Type           |
|--|--|--|
| [Payroll Engine White Paper](Documents/PayrolEnginelWhitePaper.pdf)       | Technsiche Systembeschreibung             | Manual         |
| [Payrol Examples]()                                                       | Payroll Beispiele                         | JSON/C# files  |
| [Payrol Tests]()                                                          | Automatisierte Payroll Tests              | JSON/C# files  |
| [Repository Map](Documents/PayrollEngineRepositoryMap.pdf)                | Überischt Payroll Engine Repositories     | Manual         |
| [Software Enginnering](Documents/SoftwareEngineering.md)                  | Community Guidelines                      | Manual         |
| [Client Development Tutorials](Documents/SoftwareEngineering.md)          | .NET Konsolenbeispiele                    | Repository     |
<br/>
