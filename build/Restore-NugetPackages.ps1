param
(
    # 
    [parameter(Mandatory=$false)]
    [string] $PackagesConfigPath = "..\packages.config",
    # 
    [parameter(Mandatory=$false)]
    [string] $NuGetConfigPath,
    # 
    [parameter(Mandatory=$false)]
    [string] $OutputDirectory,
    # 
    [parameter(Mandatory=$false)]
    [string] $NuGetPath,
    # 
    [parameter(Mandatory=$false)]
    [uri] $NuGetUri = 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe'
)

## Initialize
Remove-Module CommonFunctions -ErrorAction SilentlyContinue
Import-Module .\CommonFunctions.psm1

[System.IO.FileInfo] $PackagesConfigFileInfo = Get-PathInfo $PackagesConfigPath -DefaultFilename "packages.config" -ErrorAction Stop
[System.IO.FileInfo] $NuGetConfigFileInfo = Get-PathInfo $NuGetConfigPath -DefaultFilename "NuGet.config" -SkipEmptyPaths
[System.IO.DirectoryInfo] $OutputDirectoryInfo = Get-PathInfo $OutputDirectory -InputPathType Directory -SkipEmptyPaths -ErrorAction SilentlyContinue
[System.IO.FileInfo] $NuGetFileInfo = Get-PathInfo $NuGetPath -DefaultFilename "nuget.exe" -ErrorAction SilentlyContinue
#Set-Alias nuget -Value $itemNuGetPath.FullName

## Download NuGet
if (!$NuGetFileInfo.Exists) {
    Invoke-WebRequest $NuGetUri.AbsoluteUri -UseBasicParsing -OutFile $itemNuGetPath.FullName
}

## Run NuGet
$argsNuget = New-Object System.Collections.Generic.List[string]
$argsNuget.Add('restore')
$argsNuget.Add($PackagesConfigFileInfo.FullName)
if ($VerbosePreference -eq 'Continue') {
    $argsNuget.Add('-Verbosity')
    $argsNuget.Add('Detailed')
}
if ($NuGetConfigFileInfo) {
    $argsNuget.Add('-ConfigFile')
    $argsNuget.Add($NuGetConfigFileInfo.FullName)
 }
if ($OutputDirectoryInfo) {
    $argsNuget.Add('-OutputDirectory')
    $argsNuget.Add($OutputDirectoryInfo.FullName)
 }

 Use-StartProcess $NuGetFileInfo.FullName -ArgumentList $argsNuget
