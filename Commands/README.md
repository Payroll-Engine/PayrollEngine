
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
| `Publish.AdminApp.cmd` | Publish admin application to the bin folder |
| `Release.All.cmd` | Build complete release <sup>1)</sup> |
| `Release.Binaries.cmd` | Build the release binaries |
| `Release.Docs.cmd` | Build the release documents |
| `Release.Swagger.cmd` | Build the release swagger.json file |
| `Release.Version.cmd` | Set the release version <sup>1)</sup> |
| `Start.ProgramData.cmd` | Open the program data folder |
| `Test.Payruns.cmd` | Run all payrun tests |
| `VSBackup.cmd` | Create the visual studio back (call from Visual Studio Tool) |
| `WebApp.Log.cmd` | Open the web application log file in power shell |

<sup>1)</sup> see Release Build

## Release Steps

Before you start release, ensure that all projects have the same version.

### 1. Local Release
Steps to build the release:
1. Edit the file `Release.Version.cmd`
    - set the variable `version` to the new version
2. Execute the command `Release.Version.cmd`
    - confirm new version
3. Execute the command `Release.All.cmd`
    - confirm the version release
    -> creates the inary files in the folder `Bin`
    -> creates the setup in the folder `Releases\Version`

### 2. GitHub Repositories and NuGet Packages
1. Commit the `PayrollEngine.Core` repo to GitHub and build a new release
2. -> Wait until the package is public available on nuget.org (a few minutes)
3. Commit the following repos to GitHub and build new releases
    - `PayrollEngine.Client.Core`
    - `PayrollEngine.Serilog`
    - `PayrollEngine.Document`
4. -> Wait until the package `PayrollEngine.Client.Core` is public available on nuget.org (a few minutes)
5. Commit the following repos to GitHub and build new releases
    - `PayrollEngine.Client.Scripting`
    - `PayrollEngine.Client.Test`
6. -> Wait until both packages are public available on nuget.org (a few minutes)
7. Commit the following repos to GitHub and build a new release
    - `PayrollEngine.Client.Services`
8. -> Wait until the package is public available on nuget.org (a few minutes)
5. Commit the following repos to GitHub and build new releases
    - `PayrollEngine.Backend`
    - `PayrollEngine.PayrollConsole`
    - `PayrollEngine.WebApp`
    - `PayrollEngine.Client.Tutorials`
    - `Regulation.*`
    - `PayrollEngine`

### 3. GitHub Release
1. GitHub: create a new release with the same version name
    - create a new tag with the release name
    - attach the release files from the `Releases\Version` folder
2. GitHub: publish the release
3. Add to the wiki releases page

## Folders
- `Bin` - binaries (publish output)
- `Command` - command line tools
- `docs` - documents
- `Examples` - payroll examples
- `images` - images
- `Command` - command line tools
- `Packages` - local NuGet packages
- `Releases` - local release history
- `Schemas` - JSON schemas
- `Setup` - setup files
- `Tests` - payroll tests