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
