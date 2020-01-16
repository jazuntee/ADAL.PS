[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string] $ModulePath = "..\src\*.psd1"
)

Import-Module $ModulePath -Force

## Load Test Helper Functions
. (Join-Path $PSScriptRoot 'TestCommon.ps1')

## Get Test Automation Token
[hashtable] $AppConfigAutomation = @{
    ClientId = 'ada4b466-ae54-45f8-98fc-13b22708b978'
    ClientCertificate = (Get-ChildItem Cert:\CurrentUser\My\7103A1080D8611BD2CE8A5026D148938F787B12C)
    RedirectUri = 'http://localhost/'
    TenantId = 'jasoth.onmicrosoft.com'
}
$MSGraphToken = Get-MSGraphToken -ErrorAction Stop @AppConfigAutomation

try {
    ## Create applications in tenant for testing.
    $appPublicClient,$spPublicClient = New-TestAzureAdPublicClient -MSGraphToken $MSGraphToken
    $appConfidentialClient,$spConfidentialClient = New-TestAzureAdConfidentialClient -MSGraphToken $MSGraphToken
    $appConfidentialClientSecret,$ClientSecret = $appConfidentialClient | Add-AzureAdClientSecret -MSGraphToken $MSGraphToken
    $appConfidentialClientCertificate,$ClientCertificate = $appConfidentialClient | Add-AzureAdClientCertificate -MSGraphToken $MSGraphToken

    ## Add delay to allow time for application configuration and credentials to propogate.
    Write-Host "`nWaiting for application configuration and credentials to propogate..."
    Start-Sleep -Seconds 60

    ## Perform Tests
    Describe 'Get-AdalToken' {

        Context 'Public Client' {

            It 'Inline as Positional Parameter' {
                $Output = Get-AdalToken -TenantId $appPublicClient.publisherDomain -Resource 'https://graph.microsoft.com/' -ClientId $appPublicClient.appId
                $Output | Should -BeOfType [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]
            }
        }

        Context 'Confidential Client' {

            It 'Inline ClientSecret as Positional Parameter' {
                $Output = Get-AdalToken -TenantId $appConfidentialClient.publisherDomain -Resource 'https://graph.microsoft.com/' -ClientId $appConfidentialClient.appId -ClientSecret $ClientSecret
                $Output | Should -BeOfType [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]
            }

            It 'Inline ClientCertificate as Positional Parameter' {
                $Output = Get-AdalToken -TenantId $appConfidentialClient.publisherDomain -Resource 'https://graph.microsoft.com/' -ClientId $appConfidentialClient.appId -ClientAssertionCertificate $ClientCertificate
                $Output | Should -BeOfType [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult]
            }

        }

    }
}
finally {
    ## Remove client credentials
    #Write-Host 'Removing client credentials...'
    $ClientCertificate | Remove-Item -Force
    #$appConfidentialClient | Remove-AzureAdClientSecret -KeyId $appConfidentialClientSecret.keyId -MSGraphToken $MSGraphToken
    #$appConfidentialClient | Remove-AzureAdClientCertificate -KeyId $appConfidentialClientCertificate.keyId -MSGraphToken $MSGraphToken

    ## Remove test client applications
    $appPublicClient,$appConfidentialClient | Remove-TestAzureAdApplication -Permanently -MSGraphToken $MSGraphToken
}
