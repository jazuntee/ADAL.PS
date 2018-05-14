param
(
    # 
    [parameter(Mandatory=$false)]
    [string] $PackagesConfigPath = "C:\Users\jason\Source\Repos\ADAL.PS\packages.config",
    # 
    [parameter(Mandatory=$false)]
    [string] $NuGetConfigPath = "C:\Users\jason\Source\Repos\ADAL.PS\NuGet.config",
    # 
    [parameter(Mandatory=$false)]
    [string] $NuGetPath,
    # 
    [parameter(Mandatory=$false)]
    [uri] $NuGetUri = 'https://nuget.org/nuget.exe'
)

[System.IO.FileInfo] $itemNuGetPath = (Get-Location).ProviderPath
if ($NuGetPath) { $itemNuGetPath = $NuGetPath }
if (!$itemNuGetPath.Extension) { $itemNuGetPath = Join-Path $itemNuGetPath.FullName "nuget.exe" }
Set-Alias nuget -Value $itemNuGetPath.FullName

if (!$itemNuGetPath.Exists) {
    Invoke-WebRequest $NuGetUri.AbsoluteUri -UseBasicParsing -OutFile $itemNuGetPath.FullName
}

#Install-Package -Name Microsoft.IdentityModel.Clients.ActiveDirectory -ProviderName NuGet -Source "https://www.nuget.org/api/v2/" -AllowPrereleaseVersions -SkipDependencies -Force -Destination "C:\Users\jason\Source\Repos\ADAL.PS\packages" -WhatIf

#Install-Package -ProviderName NuGet -Source "https://www.nuget.org/api/v2/" -ConfigFile packages.config -AllowPrereleaseVersions -Destination "C:\Users\jason\Source\Repos\ADAL.PS\packages" -Force -SkipDependencies

nuget restore $PackagesConfigPath -Verbosity Detailed -NonInteractive -ConfigFile $NuGetConfigPath
