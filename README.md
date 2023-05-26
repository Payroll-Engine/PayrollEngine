<span style="font-size: 60px">Payroll Engine</span><br />
<pspan style="font-size: 12px">Open Global Payroll Engine</span><br /><br />

# 1 Introduction
Die PE ist Backend-Dienst zur Entwicklung individueller Lohnlösungen. Die Engine fungiert als neutraler Lohnrechner, welcher durch Regulierung gesteuert wird.

**Automatisierung Lohnprozess**<br/>
Im Fokus der Lösung steht die Automatisierung von Spezialfällen in der Lohnberechnung. Dank einem neuartigen Ansatz - dynamische Geschäftfälle und zeitbezogene Daten - werden die lohnrelevanten Informationen vom HR/Mitarbeiter zum Zeitpunkt des Falles bestimmt. Änderungen können rückwirkendend sein oder werden in der Zukunft berücksichtigt. 

Daraus resultieren folgende Vorteile:
- Die Geschäftsdaten sind zu jedem Abfragezeitpunkt gültig
- Die Geschäftsdaten können aus der Vergangenheit (was galt damals) und Zukunft (was gilt zukünftig) betrachtet werden
- Lohnläufe sind jederzeit möglich

**Forecast Analysen**<br/>
Jeder Geschäftsfall und Lohnlauf kann einem Forecast-Szenario zugeordnet werden. Diese Informationen sind isoliert von den produktiven Daten und bieten die Grundlage zur Simmulation verschiedener Geschäftssenarien.

**Regulierungen**<br/>
Die Regulierung ist eine Softwarekomponente welche die Lohnberechnung mit folgenden Objekten beschreibt: 
- Lookup: Fremddaten (Onboarding)
- Case: Daten- und Eingabemodell (Daily Business)
- Wage: Lohnabrechnung (Periodische Lohnläufe)
- Report: Datenauswertung und Austausch (Individuell)

Die Steuerung des Laufzeitverhaltens ist mit No-Code (Actions) und Low-Code (Scripting) möglich.

Für die Entwicklung einer Regulierung bestehen verschiedene Hilfsmittel:
- [Web App] Prototyping einer Lohnlösung mit einfacher und ergonomischer Bedieneroberfläche
- [Payroll Console] Entwicklung einer Lohnlösung mittels JSON/C# Dateien, inkl. Versionsmanagement und Tests
- [Visual Studio] Entwicklung einer komplexen Lohnlösung in .NET Projekten, inkl. Versionsmanagement, Tests und Debug-Support

**Further features**<br/>
Further features of the Payroll Engine:
- Moderne Web-Applikation welche das volle Spektrum der Payroll Engine unterstützt
- Multiple countries per tenant
- Multi-tenant and language support
- Handle Employees working on multiple tenant divisions
- Multiple payrun per period using differential results
- Tasks and Webhooks
- Audit data for case values and regulation objects
- Custom object attributes with REST query support
- Object clustering, grouping input and payrun objects by custom tags
- .NET SDK with client-side tools to access/exchange/test the engine data

Please read the **[Payroll Engine White Paper](Documents/PayrolEnginelWhitePaper_de.pdf)** for further informations.

**Open and free of charge**<br/>
Besides the open source nature of the PE (MIT), all third-party components used are also open source. The goal of this code disclosure is to provide a free way to develop and share your own payroll solutions.

Neben der Quelloffenheit der PE (MIT), sind auch alle genutzten Fremdkomponenten Open-Source. Ziel dieser Code-Offenlegung ist es, eine kostenlose Möglichkeit zu bieten, eigene Lohnlösungen zu entwickeln und zu teilen. 

# 2 Setup Payroll Engine
The Payroll Engine runs on Windows, Linux or MacOS. The [Setup Page](Documents/Setup.md) page describes the installation steps.

<br/>

# 3 Usage
## Build Payroll Solutions
- Setup Organisation
## REST API Integration
- [Endpoints](Documents/PayrollRestServicesEndpoints.md)
- Swagger.json
- Webhooks

<br/>

# 4 Ressources
## Documents
- Technsiche Systembeschreibung - [Payroll Engine White Paper](Documents/PayrolEnginelWhitePaper_de.pdf)
- Überischt der Payroll Engine Repositories - [Repository Map](Documents/PayrollEngineRepositoryMap.pdf")
- Übersicht der REST Endpunkte - [API Endpoints](Documents/PayrollRestServicesEndpoints.md)
- Community Guidelines and [Software Enginnering](Documents/SoftwareEngineering.md)

## Tutorials
Client Development Tutorials: [README.md] in Repository *PayrollEngine.Client.Tutorials*

## Examples
Local repository folder [Examples]

## Tests
Local repository folder [Tests]

## Payroll Console
Import/Export, Tests, Reports

## Web Application
Web Client with access to all engine features

<br/>

# License
MIT
