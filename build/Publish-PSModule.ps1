param
(
	#
    [parameter(Mandatory=$false)]
    [string] $ModulePath = ".\release\ADAL.PS\5.2.6.1",
    #
    [parameter(Mandatory=$true)]
    [string] $NuGetApiKey
)

Publish-Module -Path $ModulePath -NuGetApiKey $NuGetApiKey
