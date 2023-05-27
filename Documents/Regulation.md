# Payroll Engine Regulations
Regulierung sind ein Lösungsansatz um die Komplexität von Lohnsoftware durch Aufteilung zu reduzieren. Im Gegensatz zu vernetzten Architekturen (z.B. Micro Services), werden die Komponenten der Payroll Engine in einem Schichtenmodell geführt. Jede Schicht beinhaltet Modelle, Berechnungen und Auswertungen. Mit Konzepten der Objektvererbung lassen sich diese Informationen übersteuern und erweitern.

<p>
  <img src="Images\PayrollRegulations.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

> Durch den Vererbungsansatz sinkt mit jeder neuen Ebene die Komplexität, da sich die Auswahl der Features schichtend erhöht.

Regulierungen können zwischen Mandanten geteilt werdem, was Ressourcen schont und das Deployment stark vereinfacht. Mit der [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) lassen sich Regulierungen importieren, exportieren und testen.

<br/>

## Bestandteile der Regulation
Die Regulierung besteht aus folgenden Objekten:

| Object    | Description                            | Step    | Input                  | Output          |
|--|--|--|--|--|
| Case      | Daten- und Eingabemodell               | Input   | Case Change, Lookups   | Case Values     |
| Wage      | Lohnabrechnung                         | Process | Case Values, Lookups   | Payroll Results |
| Report    | Datenauswertung und Austausch          | Output  | Case Values, Payroll Results, Lookups | Document |
| Lookup    | Fremddaten                             | Any     | Externe Quellen        | Lookup Tables   |
| Script    | Geteilte Funktionalität                | Any     |                        | C# Code         |
<br/>
> Änderungen der Regulierung werden in einem Audit geführt.

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
Das Laufzeitverhalten wird durch Funktionen bestimmt:
<p>
  <img src="Images\Functions.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

Mittels C# Script wird zu jedem Regulierungobjekt bestimmt, wie sich die Funktion verhält. So hat zum Beispiel das Object *Wage Type* die Funktion *Wage Type Value*, welchen den Wert der Lohnart berechnet.

<br/>

## Testing Regulations
Zu jedem Verarbeitungsschritt, Case Management, Payrun und Report, bestehen autmatisierte Tests:
<p>
  <img src="Images\PayrollTesting.png" style="max-width: 500px" alt="Payroll Regulations">
</p>

<br/>

## Deployment
- NuGet based version control for application binaries and business regulations

<br/>

## Development Tools
Für die Entwicklung einer Regulierung bestehen verschiedene Hilfsmittel:
- [Web App](https://github.com/Payroll-Engine/PayrollEngine.WebApp) - Prototyping einer Lohnlösung mit einfacher und ergonomischer Bedieneroberfläche
- [Payroll Console](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole) - Entwicklung einer Lohnlösung mittels JSON/C# Dateien, inkl. Versionsmanagement und Tests
- Visual Studio, VS Code - Entwicklung einer komplexen Lohnlösung in .NET Projekten, inkl. Versionsmanagement, Tests und Debug-Support

