Set-StrictMode -Version 2.0

## Global Variables
[Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache] $TokenCache = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache
[System.Collections.Generic.Dictionary[string, Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]] $AuthenticationContexts = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]'

function Get-AdalAuthenticationContext {
    param
    (
        # Address of the authority to issue token.
        [Parameter(Mandatory = $false)]
        [string] $Authority = 'https://login.microsoftonline.com/common'
    )

    if (!$AuthenticationContexts.ContainsKey($Authority)) {
        $AuthenticationContexts[$Authority] = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $Authority, $TokenCache
    }

    return $AuthenticationContexts[$Authority]
}

function New-AdalUserIdentifier {
    param
    (
        # Id of user
        [Parameter(Mandatory = $false)]
        [string] $Id,
        # Type of user identifier
        [Parameter(Mandatory = $false)]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $Type = 'OptionalDisplayableId'
    )

    if ($Id) {
        return New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier -ArgumentList $Id, $Type
    }
    else {
        return [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::AnyUser
    }
}

function New-AdalClientCredential {
    [CmdletBinding(DefaultParameterSetName = 'ClientId')]
    param
    (
        # Identifier and secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject', Position = 1)]
        [object] $InputObject,
        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $ClientId,
        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret', Position = 2)]
        [securestring] $ClientSecret,
        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = "ClientAssertionCertificate", Position = 2)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate
    )

    ## InputObject Casting
    if ($InputObject -is [pscredential]) {
        [string] $ClientId = $InputObject.UserName
        [securestring] $ClientSecret = $InputObject.Password
    }
    elseif ($InputObject -is [System.Net.NetworkCredential]) {
        [string] $ClientId = $InputObject.UserName
        [securestring] $ClientSecret = $InputObject.SecurePassword
    }
    elseif ($InputObject -is [string]) {
        return New-AdalClientCredential -ClientId $InputObject
        #$Credential = Get-Credential -Message "Enter ClientSecret:" -UserName $InputObject
        #[string] $ClientId = $Credential.UserName
        #[securestring] $ClientSecret = $Credential.Password
    }

    ## New ClientCredential
    if ($ClientSecret) {
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList $ClientId, ([Microsoft.IdentityModel.Clients.ActiveDirectory.SecureClientSecret]$ClientSecret.Copy()))
    }
    elseif ($ClientAssertionCertificate) {
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate -ArgumentList $ClientId, $ClientAssertionCertificate)
    }

    return $ClientCredential
}

function Clear-AdalTokenCache {
    $TokenCache.Clear()
}
