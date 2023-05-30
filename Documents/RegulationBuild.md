# Payroll Engine Regulation Build

## Regulation Builder
The Payroll Engine distinguishes between two application scenarios:
|                                | Regulation Builder                     |  Regulation Developer         |
|--|--|--|
| Methodology                    | No-Code                                | Low-Code                              |
| User skills                    | - Payroll know-how<br />- Function scripting (Excel like)<br />- OO [Inheritance](https://en.wikipedia.org/wiki/Inheritance_(object-oriented_programming)) principle| - Using [JSON](https://de.wikipedia.org/wiki/JavaScript_Object_Notation)<br /> - Intermediate [C#](https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/) knowledge<br />- [GitHub](https://github.com/) and [NuGet](https://www.nuget.org/) Management |
| Building Reports <sup>1)</sup> | FastReport Designer ([Community Edition](https://fastreports.github.io/FastReport.Documentation/FastReportDesignerCommunityEdition.html)) | Microsoft [ADO.NET DataSets](https://learn.microsoft.com/en-us/dotnet/framework/data/adonet/ado-net-datasets)   |
| Engine tool                    | [Payroll Engine Web Application](https://github.com/Payroll-Engine/PayrollEngine.WebApp) | [Payroll Engine Console Application](https://github.com/Payroll-Engine/PayrollEngine.PayrollConsole)     |
| Development tool               | *not required*                        | - Visual Studio ([Windows](https://visualstudio.microsoft.com/en/vs/community/), [MacOS](https://visualstudio.microsoft.com/vs/mac/))<br />- Visual Studio Code ([Windows/Linux/MacOS](https://code.visualstudio.com/))  |
<br/>

<sup>1)</sup> Requires Low-Code development<br/>
<br/>

## Regulation Build Steps
1. Tenant [Onboarding](Onboarding.md) with an empty Regulation 
2. Build the data and input model using Cases, Case Fields and Case Relations
    - Das Datenmodell muss alle Ausgabewerte beinhalten, welche nicht berechnet werden können
    - Datenmodell und Inputmodell können variieren
    - Test driven approach: Vorgabe von Datenmodell und Datenvalidierung mit Case Tests
3. Build the Payrun using Wage Types and Collectors
    - Test driven approach: Vorgabe der Lohnergebnisse und Datenvalidierung mit Payrun Tests
4. Build the Reports
    - Test driven approach: Vorgabe der Reportdaten mit Report Tests
