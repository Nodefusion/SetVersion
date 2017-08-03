# SetVersion script for updating project build versions
SetVersion is a PowerShell script which enables you to dynamically change your project build version number while using it in your autobuild process.
It is suitable for .NET Core projects (.csproj and .nuspec) and FrontEnd projects (JavaScript .js or TypeScript .ts).
It is intended to be used as a Task in your build definition. Example, as Powershell Tasks in your Visual Studio Team Services build definition.

# Usage
You have to add your script to your project code repository which will be used in your build definition.
Next step is to add a new task in your build definition to call SetVersion.ps1 script before project build task.
`Note: In JavaScript and TypeScript files it searches for string "--version--" which will be replaced by the BuildNumber/version argument` 

# SetVersion.ps1 Arguments
SetVersion.ps1 script has 3 required parameters.
```sh
./SetVersion.ps1 -buildNumber BuildNumber -type Type -filePath filePath
```
BuildNumber - version number you wish to set for your project
Type - type of your project (csproj|nuspec|js|ts)
filePath - path to file which contains your project version

### Basics and Examples
In case of Visual Studio Team Services, PowerShell tasks which calls SetVersion.ps1 script, you will commonuse Visual Studio Team Services variables
```sh
$(Build.BuildNumber)
```
This is an environmental variable which exists by default in your build procedure, it can be fine tuned in procedure's options under the 'Build number format' setting. If you leave that setting empty, your build number will increment, and will be in an integer format so it will work. `Note: SetVersion script expects the buildNumber parameter to be an integer!` 
```sh
$(Build.SourcesDirectory)
```
This is an environmental variable which exists by default in your build procedure and it is used to position correctly on your build machine when the build is running.

#### Example for .NET Core project which has to change build number only in csproj file
```sh
-buildNumber $(Build.BuildNumber) -type csproj -filePath $(Build.SourcesDirectory)\src\ServerBackEnd\ServerBackEnd.csproj
```
#### Example for .NET Core project which has to change build number only in nuspec file
```sh
-buildNumber $(Build.BuildNumber) -type nuspec -filePath $(Build.SourcesDirectory)\src\ServerBackEnd\ServerBackEnd.nuspec
```
#### Example for .NET Core project which has to change build number in both csproj and nuspec files in the same script call
```sh
-buildNumber $(Build.BuildNumber) -type csprojnuspec -filePath $(Build.SourcesDirectory)\src\ServerBackEnd\ServerBackEnd.csproj
``` 
`Previous example assumes that nuspec and csproj files are placed in the same directory and have the same names (except extensions).` Under filePath paremeter you can point to whatever of those files you want. It is also important to emphasize that the versions will not be synced in this step. Still every of those files has it's own major, minor and maintenance numbers which will be left intact, only the revisionNumber will be the 100% same and set to the value you've passed to -buildNumber parameter.
#### Example for JavaScript project which has to change build number in an index.constants.js file
```sh
-buildNumber $(Build.BuildNumber) -type js -filePath $(Build.SourcesDirectory)\src\Portal\src\app\index.constants.js
```
`Note: SetVersion script expects the index.constants.js file to have a substring '--version--' (without quotes) which will be replaced to a value you’ve passed to -buildNumber parameter.`
If your version is in .ts file then you'll use the following example:
```sh
-buildNumber $(Build.BuildNumber) -type ts -filePath $(Build.SourcesDirectory)\src\Portal\src\app\index.constants.ts
```
