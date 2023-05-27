<span style="font-size: 60px">Payroll Engine</span><br />
<pspan>Open Global Payroll Engine</span><br /><br />

# 1 Introduction
Die Payroll Engine ist Backend-Dienst zur Entwicklung individueller Lohnlösungen für skalierbare und landesübergreifende Lohndienste. Die Engine fungiert als neutraler Lohnrechner, welcher durch Regulierung gesteuert wird.

**Automatisierung Lohnprozess**<br/>
Im Fokus der Lösung steht die Automatisierung von Spezialfällen in der Lohnberechnung. Dank einem neuartigen Ansatz - dynamische Geschäftfälle und zeitbezogene Daten - werden die lohnrelevanten Informationen vom HR/Mitarbeiter zum Zeitpunkt des Falles bestimmt. Änderungen können rückwirkendend sein oder werden in der Zukunft berücksichtigt. 

Daraus resultieren folgende Vorteile:
- Die Geschäftsdaten sind zu jedem Abfragezeitpunkt gültig
- Die Geschäftsdaten können aus der Vergangenheit (was galt damals) und Zukunft (was gilt zukünftig) betrachtet werden
- Lohnläufe sind jederzeit möglich

**Forecast Analysen**<br/>
Jeder Geschäftsfall und Lohnlauf kann einem Forecast-Szenario zugeordnet werden. Diese Informationen sind isoliert von den produktiven Daten und bieten die Grundlage zur Simmulation verschiedener Geschäftssenarien.

**Regulierungen**<br/>
Die Regulierung ist eine Softwarekomponente, welche den Lohnprozess in den Bereichen Onboarding, HR, Employee und Payrun beschreibt. Dank objektorientierten Ansätzen können Regulierungen erweitert und vernetzt werden. Weitere Infos zu [Regulierungen](Documents/Regulation.md).

Read more about the [Payroll Engine Features](Documents/Features.md) and the [White Paper](Documents/PayrolEnginelWhitePaper_de.pdf) for deeper insights.

**About this project**<br/>
Neben der Quelloffenheit der Payroll Engine (MIT Lizenz), sind auch alle genutzten Fremdkomponenten Open-Source. Ziel dieser Code-Offenlegung ist es, eine kostenlose Möglichkeit zu bieten, eigene Lohnlösungen zu entwickeln und zu teilen.

*Dieses Projekt wird bisher von mir allein entwickelt und betreut. Solltest du interesse haben am Projekt mitzuwirken, melde dich bitte bei mir. Eune weitere Form das Pèrojekt zu unterstützen sind [Spenden], welche eine Fortführung ermöglichen - Jani Giannoudis.*

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
