param
(
    #
    [parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = "..\src",
    #
    [parameter(Mandatory = $false)]
    [string] $PackagesConfigPath = "..\"
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop
[System.IO.FileInfo] $PackagesConfigFileInfo = Get-PathInfo $PackagesConfigPath -DefaultFilename "packages.config" -ErrorAction Stop

## Read Module Manifest
$ModuleManifest = Import-PowerShellDataFile $ModuleManifestFileInfo.FullName

Write-Host ('##vso[task.setvariable variable=moduleName;isOutput=true]{0}' -f $ModuleManifestFileInfo.BaseName)
Write-Host ('##vso[task.setvariable variable=moduleVersion;isOutput=true]{0}' -f $ModuleManifest.ModuleVersion)

## Read Packages Configuration
$xmlPackagesConfig = New-Object xml
$xmlPackagesConfig.Load($PackagesConfigFileInfo.FullName)

foreach ($package in $xmlPackagesConfig.packages.package) {
    Write-Host ('##vso[task.setvariable variable=package.{0};isOutput=true]{1}' -f $package.id, $package.version)
}
