
## Commands

| Command      | Description            |
|:--|:--|
| `ActionReport.cmd` | Create an action report from the backend scripting assembly |
| `ActionReport.File.cmd` | Create an action fiel report from the backend scripting assembly |
| `AppLog.cmd` | Base command for the application logcommands |
| `Backend.Log.cmd` | Open the backend log file in power shell |
| `DotNet.DevCertsHttps.cmd` | Generate HTTPS developer certificate |
| `JsonSchemaBuilder.cmd` | JSON schema build (used in project build) |
| `NuGetClearCache.cmd` | Clear the NuGet cache |
| `Pack.All.cmd` | Pack all NuGet packages |
| `Pack.All.Debug.cmd` | Pack all NuGet packages with debug info |
| `Pack.cmd` | Pack single NuGet package |
| `Pack.Debug.cmd` | Pack single NuGet package with debug info |
| `PayrollConsole.Log.cmd` | Open the payroll console log file in power shell |
| `Publish.Backend.cmd` | Publish backend to the bin folder |
| `Publish.PayrollConsole.cmd` | Publish payroll console to the bin folder |
| `Publish.Tools.cmd` | Publish tools to the bin folder |
| `Publish.WebApp.cmd` | Publish web application to the bin folder |
| `Release.All.cmd` | Build complete release <sup>1)</sup> |
| `Release.Binaries.cmd` | Build the release binaries |
| `Release.Docs.cmd` | Build the release documents |
| `Release.Swagger.cmd` | Build the release swagger.json file |
| `Release.Version.cmd` | Set the release version <sup>1)</sup> |
| `Start.ProgramData.cmd` | Open the program data folder |
| `Test.Payruns.cmd` | Run all payrun tests |
| `VSBackup.cmd` | Create the visual studio back (call from Visual Studio Tool) |
| `WebApp.Log.cmd` | Open the web application log file in power shell |

<sup>1)</sup> Before you build the release with `Release.All.cmd`, the version must be set with `Release.Version.cmd`.

## Folders
- `Bin` - binaries (publish output)
- `Command` - command line tools
- `docs` - documents
- `Examples` - payroll examples
- `images` - images
- `Command` - command line tools
- `Packages` - local NuGet packages
- `Packages` - local NuGet packages
- `Schemas` - JSON schemas
- `Setup` - setup definition
- `Tests` - payroll tests