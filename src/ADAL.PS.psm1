## Set Strict Mode for Module. https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version 2.0

Write-Warning 'The ADAL.PS PowerShell module wraps ADAL.NET functionality into PowerShell-friendly cmdlets and is not supported by Microsoft. Microsoft support does not extend beyond the underlying ADAL.NET library. For any inquiries regarding the PowerShell module itself, you may contact the author on GitHub or PowerShell Gallery.'
Write-Warning 'Microsoft has stated that "ADAL.NET is in maintenance mode and no new features will be added to ADAL.NET anymore. All our ongoing efforts will be focused on improving the new MSAL.NET." You should consider using the MSAL.PS PowerShell module which uses the new MSAL.NET library.'

## Global Variables
[Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache] $TokenCache = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache
[System.Collections.Generic.Dictionary[string, Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]] $AuthenticationContexts = New-Object 'System.Collections.Generic.Dictionary[string,Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]'
