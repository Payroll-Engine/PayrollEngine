# Payroll Engine Features


| Feature                  | Description                            | Category |
|--|--|--|
| Web Client                     | Main repository             | |

Features of the Payroll Engine:
- Sc
- Multiple countries per tenant
- Multi-tenant and language support
- Handle Employees working on multiple tenant divisions
- Multiple payruns per period with differential results
- User Tasks
- Webhooks
- Audit data for case values and regulation objects
- Custom object attributes with REST query support
- Object clustering, grouping input and payrun objects by custom tags
- .NET SDK with client-side tools to access/exchange/test the engine data


- Disruptive concepts
    - Business software is extracted from the payroll backend engine
    - Stackable business software based on regulations 
    - Case driven data model with uniform input
    - Timeline based case data (Event Sourcing instead of table)
        - Always valid data considering retrospective and scheduled changes
        - Consider the values as they were in the past and as they will be in the future
- Customer benefits
    - HR and Employee (End-user): simple input on changes
    - Payroll Service Provider and Enterprise (Business Customer): use of free/commercial regulations and flexible company customizing
    - Regulation Provider (Business Solution): provide country and business regulations
    - ERP/HR Software (Platform): scalable payroll engine with an open cloud API
- Globalization and vertical applications
    - Multiple countries per tenant
    - Employee with salary from different divisions/countries 
    - Shared and consolidated country data and applications (Regulation)
    - Vertical applications (Regulation) over multiple tenants
- Case driven model
    - Global, National, Company and Employee case types
    - Unlimited input cancellation
    - Dynamic input workflow with related cases
- Payroll calculation
    - Transform case values to pay period
    - Automatic and manual retro calculations
    - Forecast scenarios
- Scripting API (Low-code with C#)
    - Case Management
        - Local scripting development
        - No-code with actions
        - Custom or third party business cases (Regulation)
    - Payrun
        - Value collection during wage calculation
        - Integration Webhooks
        - Custom or third party business applications (Regulation)
    - Report
        - Local scripting development
        - Data queries on REST GET endpoints
        - Custom report render, transformation and validation 
        - Custom or third party reports and exports (Regulation)
- Automated Tests (JSON & C#)
    - Case Management
    - Payrun
    - Report
- Regulation (Business Application Layer in JSON)
    - Open source or commercial
    - Multiple regulation version on the timeline (Valid-From date)
    - Container for data (lookup), input (cases), process (payrun), output (report) and tools (C# scripts)
    - OO principles (override objects)
    - Shared regul between tenants
    - NuGet public and local deployment
- Basic Features
    - Multi tenant
    - Multi language
    - Employee on multiple tenant divisions
    - Multiple payrun per period (differential results)
    - Custom object attributes (with REST query support)
    - Object clustering (grouping and filtering by custom tags)
    - Audit data for case values and regulation objects
    - REST API: partial OData support (queries)
    - Tasks and Webhooks
    - Payroll Clients
        - Console app
        - Report console app (Syncfusion)
        - Web app (Blazor and Syncfusion)
    - SDK (.Net)
        - HTML Help
        - Client Services Tutorial (Git Repo)


