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
