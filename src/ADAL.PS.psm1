## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 2.0

Write-Warning 'The ADAL.PS PowerShell module wraps ADAL.NET functionality into PowerShell-friendly cmdlets and is not supported by Microsoft. Microsoft support does not extend beyond the underlying ADAL.NET library. For any inquiries regarding the PowerShell module itself, you may contact the author on GitHub or PowerShell Gallery.'

## Global Variables
[Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache] $TokenCache = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache
[System.Collections.Generic.Dictionary[string, Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]] $AuthenticationContexts = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]'
