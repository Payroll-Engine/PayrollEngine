# Payroll Engine REST Service Endpoints
[Payroll Engine](https://github.com/Payroll-Engine) web application (Blazor):

## Endpoints
| Controller           | Endpoint                                | Comment                                       | Object     | GET                      | POST              | PUT          | DELETE         |
|--|--|--|--|--|--|--|--|
<b>System</b>                 | health/live                             | Test system health state (fast)               |            | Get health state         | | | |
""                     | health/ready                            | Test system detail health state (slow)        |            | Get health state         | | | |
""                     | health/ui                               | Used by the healt state UI                    |            | Health UI                | | | |
Admin                  | admin/application/stop                  |                                               |            |                          | Stop application  | | |
""                     | admin/application/clearcache            |                                               |            |                          | Clear application cache | | | 
""                     | admin/application/reportmethods         |                                               | string[]   | Get API report methods   | | |
Shared                 | shares/regulations                      |                                  | RegulationShare[], int  | Query regulation shares  | Add regulation share | | | 
""                     | shares/regulations/:id                  |                                         | SharedRegulation | Get regulation share     | | | Delete regulation share |
""                     | shares/regulations/:id/attributes/:an   | (an: attribute name)                          | JSON       | Get regulation share attribute | Set regulation share attribute | | Delete regulation share attribute |
Tenant                 | tenants                                 |                                               | Tenant[]   | Query tenants            | Add tenant         | | |
""                     | tenants/:id                             |                                               | Tenant     | Get tenant               | | Update tenant | Delete tenant |
""                     | tenants/:id/attributes/:an              |  (an: attribute name)                         | JSON       | Get tenant attribute     | Set tenant attribute | | Delete tenant attribute |
""                     | tenants/:id/shared/regulations          |                                             | Regulation[] | Get shared regulations   | | | |
""                     | tenants/:id/calendar/periods            |                                               | DatePeriod |                          | Get calendar period <sup>1)</sup> | | |
""                     | tenants/:id/calendar/cycles             |                                               | DatePeriod |                          | Get calendar cycle <sup>1)</sup> | |  |
""                     | tenants/:id/calendar/values             |                                               | String     |                          | Calculate calendar value <sup>1)</sup> | | |
""                     | tenants/:id/queries                     |                                               | DataTable  |                          | Execute report query <sup>1)</sup> | | |
""                     | tenants/:id/actions                     |                                             | ActionInfo[] | Get system action infos  | | | |
User                   | tenants/:id/users                       |                                               | User[], int| Query users              | Add user           | | |
""                     | tenants/:id/users/:id                   |                                               | User       | Get user                 |                    | Update user | Delete user |
""                     | tenants/:id/users/:id/password          |                                               | string     |                          | Test user password <sup>1)</sup> | Update user password | |
""                     | tenants/:id/users/:id/attributes/:an    |  (an: attribute name)                         | JSON       | Get tenant attribute     | Set user attribute | | Delete user attribute |





<sup>1\)</sup> use of POST instead of GET according RFC7231 https://datatracker.ietf.org/doc/html/rfc7231#section-4.3.1

