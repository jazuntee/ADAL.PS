param
(
    # Path to Module Root Directory
    [Parameter(Mandatory = $false)]
    [string] $ModuleDirectory,
    #
    [Parameter(Mandatory = $false)]
    [string] $SigningCertificateBase64,
    #
    [Parameter(Mandatory = $false)]
    [X509Certificate] $SigningCertificate = (Get-ChildItem Cert:\CurrentUser\My\E7413D745138A6DC584530AECE27CEFDDA9D9CD6 -CodeSigningCert),
    #
    [Parameter(Mandatory = $false)]
    [string] $TimestampServer = 'http://timestamp.digicert.com'
)

$kvSecretBytes = [System.Convert]::FromBase64String($SigningCertificateBase64)
$certCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certCollection.Import($kvSecretBytes, $null, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

$SigningCertificate = $certCollection

## Sign PowerShell Files
Set-AuthenticodeSignature (Join-Path $ModuleDirectory '*.ps*1*') -Certificate $SigningCertificate -HashAlgorithm SHA256 -IncludeChain NotRoot -TimestampServer $TimestampServer
