# Payroll Engine Regulations
Regulierung sind ein Lösungsansatz um die Komplexität von Lohnsoftware durch Aufteilung zu reduzieren. Im Gegensatz zu vernetzten Architekturen (z.B. Micro Services), werden die Komponenten der Payroll Engine in einem Schichtenmodell geführt. Jede Schicht beinhaltet Modelle, Berechnungen und Auswertungen. Mit Konzepten der Objektvererbung lassen sich diese Informationen übersteuern und erweitern.

<p>
  <img src="Images\PayrollRegulations.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

> Die [Web Application](https://github.com/Payroll-Engine/PayrollEngine.WebApp.git) unterstützt das Editieren der Regulierung unter Berücksichtigung der Vererbungshierarchie.

Regulierungen können zwischen Mandanten geteilt werdem, was Ressourcen schont und das Deployment stark vereinfacht. Mit der [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) lassen sich Regulierungen importieren, exportieren und testen.

<br/>

## Bestandteile der Regulation
Die Regulierung besteht aus folgenden Objekten:

| Topic  |  Description                   | Objects                                    | Input                  | Output          |
|--|--|--|--|--|
| Case   | Daten- und Eingabemodell      | Case<br />Case Field<br />Case Relation             | Case Change<br />Lookups   | Case Values     |
| Wage   | Lohnabrechnung                | Collector<br />Wage Type                        | Case Values<br />Lookups   | Payroll Results |
| Report | Datenauswertung und Austausch | Report<br />Report Parameter<br />Report Template   | Case Values<br />Payroll Results<br />Lookups | Document |
| Lookup | Fremddaten                    | Lookup<br />Lookup Value                        | Externe Quellen        | Lookup Tables   |
| Script | Geteilte Funktionalität       | Script                                      |                        | C# Code         |
<br/>

Ein Regulierungsobjekt besitzt folgende Eigneschaften:
- Audit Trail der Modifikationen
- Erweiterbar mit benutzerdefinierten Attributen
- Zuordnung zu Clusters, Tag-Mechanismus zur Gruppierung und Filterung von Eingabe- und Lohnlaufdaten
- Besitzt eine Identifikation, welcher als Schlüssel zur Überlagerung dient

## Reports
Obwohl der Report Bestandteil der Regulierung ist, sind die Verantwortlichkeiten aufgeteilt:
- Die Aufbereitung der Reportdaten erfolgt in Backend-Scripts
- Für die Transformation der Daten in Dokumente/Dateien ist die Clientanwendung zuständig

Das Repository [Document](https://github.com/Payroll-Engine/PayrollEngine.Document) bietet eine Arbeitsgrundlage, basierend auf der Open Source Varianten von [Fast Reports](https://github.com/FastReports). Um ein alternatives Reporting-Tool zu verwenden, muss ein entsprechendes Document-Repository bereitgestellt werden.

> Die Aufbereitung von Schnittstellendaten erfolgt ebenfalls mit Reports.

<br/>

## Actions
Mit Actions wird die Dateneingabe ohne Progrmammierkentnisse gesteuert. Ein Action ist wie bei Excel eine vordefinierte Funktion welche auch bedingt ausgeführt werden, wie die Excel Funktion *IIf(expression, true, false)*. Die Action kann auf Lookup- und Case-Daten zurückgreifen.
<p>
  <img src="Images\CaseActions.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

<br/>

> Die Regulierung kann in Scripts eigene Actions anbieten

## Functions
Das Laufzeitverhalten wird durch Funktionen bestimmt. Jedes Regulierungsobjekt bietet entsprechende Funktionen an, zum Beispiel das Object *Wage Type* die Funktion *Wage Type Value*. Mit C# Code (Script Expression) wird die Funktion vervollständigt.

Verfügbare Funktionen: 
<p>
  <img src="Images\Functions.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

> Die Case und Report Funktionen unterstützen lokales Debugging.

<br/>

## Regulation Tests
Zu jedem Verarbeitungsschritt, Case Management, Payrun und Report, bestehen autmatisierte Tests:
<p>
  <img src="Images\PayrollTesting.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

> Die Payrun Tests erfolgen über mehrere Lohnperioden und eigenen sich als Nachweis für Software-Zertifikation. 

Die Steuerung der Tests erfolgt mit der [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole). 

<br/>

## Deployment
Eine Regulierung besteht aus JSON, C# und Report Dateien, welche als [NuGet](https://www.nuget.org/) Packet verteilt werden. Mit diesem Tool werden die Regulierungen versioneirt und deren Abhängigkeiten aufgelöst.

<br/>

## Development Tools
Für die Entwicklung einer Regulierung bestehen verschiedene Hilfsmittel:
- [Web App](https://github.com/Payroll-Engine/PayrollEngine.WebApp) - Prototyping einer Lohnlösung mit einfacher und ergonomischer Bedieneroberfläche
- [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) - Entwicklung einer Lohnlösung mittels JSON/C# Dateien, inkl. Versionsmanagement und Tests
- Visual Studio, VS Code - Entwicklung einer komplexen Lohnlösung in .NET Projekten, inkl. Versionsmanagement, Tests und Debug-Support

