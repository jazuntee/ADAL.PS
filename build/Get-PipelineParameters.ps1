param
(
    #
    [parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = "..\src\*.psm1",
    #
    [parameter(Mandatory = $false)]
    [string] $PackagesConfigPath = "..\"
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop
[System.IO.FileInfo] $PackagesConfigFileInfo = Get-PathInfo $PackagesConfigPath -DefaultFilename "packages.config" -ErrorAction Stop

## Read Module Manifest
$ModuleManifest = Import-PowerShellDataFile $ModuleManifestFileInfo.FullName -ErrorAction Stop

Write-Host ('##vso[task.setvariable variable=moduleName;isOutput=true]{0}' -f $ModuleManifestFileInfo.BaseName)
Write-Host ('##[debug] {0} = {1}' -f 'moduleName', $env:moduleName)

Write-Host ('##vso[task.setvariable variable=moduleVersion;]{0}' -f $ModuleManifest.ModuleVersion)
Write-Host ('##[debug] {0} = {1}' -f 'moduleVersion', $env:moduleVersion)

## Read Packages Configuration
$xmlPackagesConfig = New-Object xml
$xmlPackagesConfig.Load($PackagesConfigFileInfo.FullName)

foreach ($package in $xmlPackagesConfig.packages.package) {
    Write-Host ('##vso[task.setvariable variable=version.{0};isOutput=true]{1}' -f $package.id, $package.version)
    Write-Host ('##[debug] version.{0} = {1}' -f $package.id, $package.version)
}
