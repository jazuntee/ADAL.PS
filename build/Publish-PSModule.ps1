param
(
	#
    [parameter(Mandatory=$false)]
    [string] $ModulePath = ".\release\ADAL.PS\3.19.8.1",
    #
    [parameter(Mandatory=$true)]
    [string] $NuGetApiKey
)

Publish-Module -Path $ModulePath -NuGetApiKey $NuGetApiKey
