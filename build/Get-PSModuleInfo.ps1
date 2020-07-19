param
(
    #
    [parameter(Mandatory = $false)]
    [string] $ModuleManifestPath = "..\src",
    #
    [parameter(Mandatory = $false)]
    [string] $PackagesConfigPath = "..\",
    #
    [parameter(Mandatory = $false)]
    [switch] $TrimRevisionNumber
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

[System.IO.FileInfo] $ModuleManifestFileInfo = Get-PathInfo $ModuleManifestPath -DefaultFilename "*.psd1" -ErrorAction Stop
[System.IO.FileInfo] $PackagesConfigFileInfo = Get-PathInfo $PackagesConfigPath -DefaultFilename "packages.config" -ErrorAction SilentlyContinue

## Read Module Manifest
$ModuleManifest = Import-PowerShellDataFile $ModuleManifestFileInfo.FullName -ErrorAction Stop

## Output moduleName Azure Pipelines
Write-Host ('##vso[task.setvariable variable=moduleName;isOutput=true]{0}' -f $ModuleManifestFileInfo.BaseName)
Write-Host ('##[debug] {0} = {1}' -f 'moduleName', $ModuleManifestFileInfo.BaseName)

## Output moduleVersion Azure Pipelines
[version] $ModuleVersion = $ModuleManifest.ModuleVersion
if ($TrimRevisionNumber) { $ModuleVersion = $ModuleManifest.ModuleVersion -replace '(?<=^(.?[0-9]+){3,}).[0-9]+$', '' }
Write-Host ('##vso[task.setvariable variable=moduleVersion;isOutput=true]{0}' -f $ModuleVersion)
Write-Host ('##[debug] {0} = {1}' -f 'moduleVersion', $ModuleVersion)

## Read Packages Configuration
if ($PackagesConfigFileInfo.Exists) {
    $xmlPackagesConfig = New-Object xml
    $xmlPackagesConfig.Load($PackagesConfigFileInfo.FullName)

    foreach ($package in $xmlPackagesConfig.packages.package) {
        ## Output packageVersion Azure Pipelines
        Write-Host ('##vso[task.setvariable variable=version.{0};isOutput=true]{1}' -f $package.id, $package.version)
        Write-Host ('##[debug] version.{0} = {1}' -f $package.id, $package.version)
    }
}
