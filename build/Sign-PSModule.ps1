param
(
    # Path to Module Root Directory
    [Parameter(Mandatory = $false)]
    [string] $ModuleDirectory = "..\build\release\*\*",
    # Specifies the certificate that will be used to sign the script or file.
    [Parameter(Mandatory = $false)]
    [object] $SigningCertificate = (Get-ChildItem Cert:\CurrentUser\My\E7413D745138A6DC584530AECE27CEFDDA9D9CD6 -CodeSigningCert),
    # Uses the specified time stamp server to add a time stamp to the signature.
    [Parameter(Mandatory = $false)]
    [string] $TimestampServer = 'http://timestamp.digicert.com'
)

## Initialize
Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force -WarningAction SilentlyContinue -ErrorAction Stop

## Parse Signing Certificate
if ($SigningCertificate -is [System.Security.Cryptography.X509Certificates.X509Certificate2]) { }
elseif ($SigningCertificate -is [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]) { $SigningCertificate = $SigningCertificate[-1] }
else { $SigningCertificate = Get-X509Certificate $SigningCertificate -EndEntityCertificateOnly }

## Sign PowerShell Files
Set-AuthenticodeSignature "$ModuleDirectory\*.ps*1" -Certificate $SigningCertificate -HashAlgorithm SHA256 -IncludeChain NotRoot -TimestampServer $TimestampServer
