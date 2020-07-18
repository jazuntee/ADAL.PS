param
(
    # Path to Module
    [Parameter(Mandatory = $false)]
    [string] $ModulePath = ".\release\ADAL.PS",
    # Repository for PowerShell Gallery
    [Parameter(Mandatory = $false)]
    [string] $RepositorySourceLocation = 'https://www.powershellgallery.com/api/v2',
    # API Key for PowerShell Gallery
    [Parameter(Mandatory = $true)]
    [string] $NuGetApiKey,
    # Unlist from PowerShell Gallery
    [Parameter(Mandatory = $false)]
    [switch] $Unlist
)

## Initialize
$ModuleManifestPath = Get-Item $ModulePath
if ($ModuleManifestPath -is [System.IO.DirectoryInfo]) {
    $ModuleManifestPath = Get-ChildItem $ModulePath -Filter "*.psd1"
    if (!$ModuleManifestPath) {
        $ModuleManifestPath = Get-ChildItem (Join-Path $ModulePath (Join-Path "*.*.*" "*.psd1")) | Select-Object -Last 1
    }
}

## Publish
$PSRepositoryAll = Get-PSRepository
$PSRepository = $PSRepositoryAll | Where-Object SourceLocation -like "$RepositorySourceLocation*"
if (!$PSRepository) {
    try {
        [string] $RepositoryName = New-Guid
        Register-PSRepository $RepositoryName -SourceLocation $RepositorySourceLocation
        $PSRepository = Get-PSRepository $RepositoryName
        Publish-Module -Path $ModuleManifestPath.DirectoryName -NuGetApiKey $NuGetApiKey -Repository $RepositoryName
    }
    finally {
        Unregister-PSRepository $RepositoryName
    }
}
else {
    Publish-Module -Path $ModuleManifestPath.DirectoryName -NuGetApiKey $NuGetApiKey -Repository $PSRepository.Name
}

if ($Unlist) {
    $ModuleManifest = Import-PowerShellDataFile $ModuleManifestPath.FullName
    Invoke-RestMethod -Method Delete -Uri ("{0}/{1}/{2}" -f $PSRepository.PublishLocation, $ModuleManifestPath.BaseName, $ModuleManifest.ModuleVersion) -Headers @{ 'X-NuGet-ApiKey' = $NuGetApiKey }
}
