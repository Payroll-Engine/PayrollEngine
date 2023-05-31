# Payroll Engine Company Setup

Die Firmen kann auf verschiedene Weisen eingerichtet werden:
- Interaktiv in der Web Applikation
- Im Konsolemodus mit mit der Payroll Console
- Rest API Requests z.B. mit Postman

Im folgenden wird das Setup mit der Konsolemodus beschrieben.

## Vorbereitung 
- Der Payroll Backend Server ist gestartet [Setup](Setup.md)
- Für das Onbaording in der Web Applikation
    -Laufender [Applikations-Server](https://github.com/Payroll-Engine/PayrollEngine.WebApp) werden 
- Für das Onbaording mit der Konsoleapplikation
    - Zugriff auf das Payroll Exchange [JSON Schema](https://github.com/Payroll-Engine/PayrollEngine/blob/main/Schemas/PayrollEngine.Exchange.schema.json)
    - JSON Editor, z.B. [Visual Studio Code](https://code.visualstudio.com/)

Das Company Onboarding erfolgt in folgenden Schritten:
| Step                   | JSON lines | Web Application feature        | REST web method      |
|--|--|--|--|
| Add Tenant             | #04 - #05  | Tenants > Add                  | *CreateTenant*       |
| Add User               | #06 - #13  | Users > Add                    | *CreateUser*         |
| Add Division           | #14 - #19  | Divisons > Add                 | *CreateDivision*     |
| Add Employee           | #21 - #27  | Employees > Add                | *CreateEmployee*     |
| Add Regulation         | #30 - #35  | Regulations > Add              | *CreateRegulation*   |
| Add Payroll and layers | #37 - #48  | Payroll Layers > Add<br />Payrolls > Add                 | *CreatePayrollLayer*<br />*CreatePayroll*      |
| Add Payrun             | #50 - #55  | Payruns > Add                  | *CreatePayrun*       |
<br />

## Company JSON
Zu konfortablen Erfassung der Firmendaten dient das JSON-Schema
```
PayrollEngine.Exchange.schema.json
```
welches eingebunden wird (Zeile #02):

```json
01 {
02   "$schema": "../../Schemas/PayrollEngine.Exchange.schema.json",
03   "tenants": [
04     {
05       "identifier": "Namespace",
06       "users": [
07         {
08           "identifier": "peter.schmid@foo.com",
09           "firstName": "Peter",
10           "lastName": "Schmid",
11           "language": "Italian"
12          }
13       ],
14       "divisions": [
15         {
16           "name": "Namespace.Division",
17           "culture": "de-CH"
18         }
19       ],
20       "employees": [
21         {
22           "identifier": "višnja.müller@foo.com",
23           "firstName": "Višnja",
24           "lastName": "Müller",
25           "divisions": [
26             "Namespace.Division"
27           ]
28         }
29       ],
30       "regulations": [
31         {
32           "name": "Namespace.Payroll",
33           "description": "The Namespace payroll"
34         }
35       ],
36       "payrolls": [
37         {
38           "name": "Namespace.Payroll",
39           "divisionName": "Namespace.Division",
40           "calendarCalculationMode": "MonthCalendarDay",
41           "layers": [
42            {
43              "level": 1,
44              "priority": 1,
45              "regulationName": "Namespace.Payroll"
46            }
47          ]
48        }
49       ],
50       "payruns": [
51         {
52           "payrollName": "Namespace.Payroll",
53           "name": "Namespace.PayrollPayrun1"
54         }
55       ]
56     }
57   ]
58 }
```

## Payroll Import
Das oben aufgeführte Beispiel wird als *Payroll.json* Datei gespeichert und mit der Payroll Konsole zum Backend übermittelt:
```
PayrollConsole PayrollImport Payroll.json
```

## Ready to build a Reulation
Das Unternehmen ist nun im System erfasst und es folgt die [Enwticklung](Documents/RegulationBuild.md) der Payroll Regulation.
