Set-StrictMode -Version 2.0

## Global Variables
[Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache] $TokenCache = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache
[System.Collections.Generic.Dictionary[string,Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]] $AuthenticationContexts = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]'

function Get-ADALAuthenticationContext {
    param
    (
        # Address of the authority to issue token.
        [parameter(Mandatory=$false)]
        [string] $Authority = 'https://login.microsoftonline.com/common'
    )

    if (!$AuthenticationContexts.ContainsKey($Authority)) {
        $AuthenticationContexts[$Authority] = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $Authority, $TokenCache
    }

    return $AuthenticationContexts[$Authority]
}

function New-ADALUserIdentifier {
    param
    (
        # Id of user
        [parameter(Mandatory=$false)]
        [string] $Id,
        # Type of user identifier
        [parameter(Mandatory=$false)]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $Type = 'OptionalDisplayableId'
    )

    if ($Id) {
        return New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier -ArgumentList $Id,$Type
    }
    else {
        return [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier]::AnyUser
    }
}

function New-ADALClientCredential {
    [CmdletBinding(DefaultParameterSetName='ClientId')]
    param
    (
        # Identifier and secure secret of the client requesting the token.
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName='InputObject', Position=1)]
        [object] $InputObject,
        # Identifier of the client requesting the token.
        [parameter(Mandatory=$true, Position=1)]
        [string] $ClientId,
        # Secure secret of the client requesting the token.
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret', Position=2)]
        [securestring] $ClientSecret,
        # Client assertion certificate of the client requesting the token.
        [parameter(Mandatory=$true, ParameterSetName="ClientAssertionCertificate", Position=2)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate
    )

    ## InputObject Casting
    if($InputObject -is [pscredential]) {
        [string] $ClientId = $InputObject.UserName
        [securestring] $ClientSecret = $InputObject.Password
    }
    elseif($InputObject -is [System.Net.NetworkCredential]) {
        [string] $ClientId = $InputObject.UserName
        [securestring] $ClientSecret = $InputObject.SecurePassword
    }
    elseif ($InputObject -is [string]) {
        return New-ADALClientCredential -ClientId $InputObject
        #$Credential = Get-Credential -Message "Enter ClientSecret:" -UserName $InputObject
        #[string] $ClientId = $Credential.UserName
        #[securestring] $ClientSecret = $Credential.Password
    }

    ## New ClientCredential
    if ($ClientSecret) {
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential -ArgumentList $ClientId,([Microsoft.IdentityModel.Clients.ActiveDirectory.SecureClientSecret]$ClientSecret.Copy()))
    }
    elseif ($ClientAssertionCertificate) {
        [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = (New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate -ArgumentList $ClientId,$ClientAssertionCertificate)
    }

    return $ClientCredential
}

function Get-ADALToken {
    [CmdletBinding(DefaultParameterSetName='Implicit')]
    param
    (
        # Tenant identifier of the authority to issue token.
        [parameter(Mandatory=$false)]
        [string] $TenantId = "common",

        # Address of the authority to issue token. This value overrides TenantId.
        [parameter(Mandatory=$false)]
        [string] $Authority = "https://login.microsoftonline.com/$TenantId",

        # Identifier of the target resource that is the recipient of the requested token.
        [parameter(Mandatory=$true)]
        [string] $Resource,

        # Identifier of the client requesting the token.
        [parameter(Mandatory=$true)]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret')]
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret-AuthorizationCode')]
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret-OnBehalfOf')]
        [securestring] $ClientSecret,

        # Client assertion certificate of the client requesting the token.
        [parameter(Mandatory=$true, ParameterSetName='ClientAssertionCertificate')]
        [parameter(Mandatory=$true, ParameterSetName='ClientAssertionCertificate-AuthorizationCode')]
        [parameter(Mandatory=$true, ParameterSetName='ClientAssertionCertificate-OnBehalfOf')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # The authorization code received from service authorization endpoint.
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret-AuthorizationCode')]
        [parameter(Mandatory=$true, ParameterSetName='ClientAssertionCertificate-AuthorizationCode')]
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [parameter(Mandatory=$true, ParameterSetName='ClientSecret-OnBehalfOf')]
        [parameter(Mandatory=$true, ParameterSetName='ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [parameter(Mandatory=$false, ParameterSetName='ClientSecret-OnBehalfOf')]
        [parameter(Mandatory=$false, ParameterSetName='ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertionType,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory=$false, ParameterSetName='Implicit')]
        [parameter(Mandatory=$false, ParameterSetName='ClientSecret-AuthorizationCode')]
        [parameter(Mandatory=$false, ParameterSetName='ClientAssertionCertificate-AuthorizationCode')]
        [uri] $RedirectUri = 'urn:ietf:wg:oauth:2.0:oob',

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory=$false, ParameterSetName='Implicit')]
        #[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior] $PromptBehavior = 'Auto',
        [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior] $PromptBehavior,

        # Identifier of the user the token is requested for.
        [Parameter(Mandatory=$false, ParameterSetName='Implicit')]
        [string] $UserId,

        # Type of identifier of the user the token is requested for.
        [Parameter(Mandatory=$false, ParameterSetName='Implicit')]
        #[Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $UserIdType = 'OptionalDisplayableId',
        [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $UserIdType,

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory=$false, ParameterSetName='Implicit')]
        [string] $extraQueryParameters
    )    

    [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthenticationContext = Get-ADALAuthenticationContext $Authority

    switch -Wildcard ($PSCmdlet.ParameterSetName)
    {
        "ClientSecret*" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = New-ADALClientCredential -ClientId $ClientId -ClientSecret $ClientSecret
            break
        }
        "ClientAssertionCertificate*" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = New-ADALClientCredential -ClientId $ClientId -ClientAssertionCertificate $ClientAssertionCertificate
            break
        }
    }

    switch -Wildcard ($PSCmdlet.ParameterSetName)
    {
        'Implicit' {
            $PlatformParameters = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList $PromptBehavior
            $UserIdentifier = New-ADALUserIdentifier $UserId -Type $UserIdType
    
            if ($extraQueryParameters) {
                [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource,$ClientId,$RedirectUri,$PlatformParameters,$UserIdentifier,$extraQueryParameters).GetAwaiter().GetResult();
            }
            elseif ($UserId) {
                [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource,$ClientId,$RedirectUri,$PlatformParameters,$UserIdentifier).GetAwaiter().GetResult();
            }
            else {
                [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource,$ClientId,$RedirectUri,$PlatformParameters).GetAwaiter().GetResult();
            }
            break
        }
        "ClientSecret" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource,$ClientCredential).GetAwaiter().GetResult();
            break
        }
        "ClientAssertionCertificate" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource,$ClientCredential).GetAwaiter().GetResult();
            break
        }
        "*AuthorizationCode" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenByAuthorizationCodeAsync($AuthorizationCode,$RedirectUri,$ClientCredential,$Resource).GetAwaiter().GetResult();
            break
        }
        "*OnBehalfOf" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion] $UserAssertionObj = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion -ArgumentList $UserAssertion, $UserAssertionType
            [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Scopes,$ClientCredential,$UserAssertionObj).GetAwaiter().GetResult();
            break
        }
    }

    return $AuthenticationResult
}

function Clear-ADALTokenCache {
    $TokenCache.Clear()
}
