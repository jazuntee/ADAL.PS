function Get-AdalToken {
    [CmdletBinding(DefaultParameterSetName = 'Implicit')]
    param
    (
        # Tenant identifier of the authority to issue token.
        [Parameter(Mandatory = $false)]
        [string] $TenantId = "common",

        # Address of the authority to issue token. This value overrides TenantId.
        [Parameter(Mandatory = $false)]
        [string] $Authority = "https://login.microsoftonline.com/$TenantId",

        # Identifier of the target resource that is the recipient of the requested token.
        [Parameter(Mandatory = $true)]
        [string] $Resource,

        # Identifier of the client requesting the token.
        [Parameter(Mandatory = $true)]
        [string] $ClientId,

        # Secure secret of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [securestring] $ClientSecret,

        # Client assertion certificate of the client requesting the token.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2] $ClientAssertionCertificate,

        # The authorization code received from service authorization endpoint.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [string] $AuthorizationCode,

        # Assertion representing the user.
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertion,

        # Type of the assertion representing the user.
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-OnBehalfOf')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate-OnBehalfOf')]
        [string] $UserAssertionType,

        # Address to return to upon receiving a response from the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientSecret-AuthorizationCode')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ClientAssertionCertificate-AuthorizationCode')]
        [uri] $RedirectUri = 'urn:ietf:wg:oauth:2.0:oob',

        # Indicates whether AcquireToken should automatically prompt only if necessary or whether it should prompt regardless of whether there is a cached token.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior] $PromptBehavior = 'Auto',

        # Identifier of the user the token is requested for.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $UserId,

        # Type of identifier of the user the token is requested for.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifierType] $UserIdType = 'OptionalDisplayableId',

        # This parameter will be appended as is to the query string in the HTTP authentication request to the authority.
        [Parameter(Mandatory = $false, ParameterSetName = 'Implicit')]
        [string] $extraQueryParameters
    )

    [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext] $AuthenticationContext = Get-AdalAuthenticationContext $Authority

    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        "ClientSecret*" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential] $ClientCredential = New-AdalClientCredential -ClientId $ClientId -ClientSecret $ClientSecret
            break
        }
        "ClientAssertionCertificate*" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate] $ClientCredential = New-AdalClientCredential -ClientId $ClientId -ClientAssertionCertificate $ClientAssertionCertificate
            break
        }
    }

    [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationResult] $AuthenticationResult = $null
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        'Implicit' {
            $PlatformParameters = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters -ArgumentList $PromptBehavior
            $UserIdentifier = New-AdalUserIdentifier $UserId -Type $UserIdType

            if ($extraQueryParameters) {
                $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters, $UserIdentifier, $extraQueryParameters).GetAwaiter().GetResult();
            }
            elseif ($UserId) {
                $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters, $UserIdentifier).GetAwaiter().GetResult();
            }
            else {
                $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientId, $RedirectUri, $PlatformParameters).GetAwaiter().GetResult();
            }
            break
        }
        "ClientSecret" {
            $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential).GetAwaiter().GetResult();
            break
        }
        "ClientAssertionCertificate" {
            $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Resource, $ClientCredential).GetAwaiter().GetResult();
            break
        }
        "*AuthorizationCode" {
            $AuthenticationResult = $AuthenticationContext.AcquireTokenByAuthorizationCodeAsync($AuthorizationCode, $RedirectUri, $ClientCredential, $Resource).GetAwaiter().GetResult();
            break
        }
        "*OnBehalfOf" {
            [Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion] $UserAssertionObj = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.UserAssertion -ArgumentList $UserAssertion, $UserAssertionType
            $AuthenticationResult = $AuthenticationContext.AcquireTokenAsync($Scopes, $ClientCredential, $UserAssertionObj).GetAwaiter().GetResult();
            break
        }
    }

    return $AuthenticationResult
}
