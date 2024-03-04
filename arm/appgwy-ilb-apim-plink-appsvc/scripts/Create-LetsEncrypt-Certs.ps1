#Option 2 (PFX Password set via New-PACertificate cmdlet)
[string]$LetsEncryptServerType = "LE_STAGE"
[string]$domain = "api.kainiindustries.net"
[string]$EmailAddress = "christian.bellee@gmail.com"

# Explicitly set how PowerShell responds to a non-terminating error
$ErrorActionPreference = 'Stop'

$CertificatePassword = "M1cr0soft1234567890"

# Let's Encrypt Server Selection
Set-PAServer -DirectoryUrl $LetsEncryptServerType

# Let's Encrypt Account Setup (including checking if among email address(es) we have empty strings, and omit them)
New-PAAccount -AcceptTOS -Contact $EmailAddress -KeyLength 2048 -Force

# Let's Encrypt Create an Order
New-PAOrder -Domain $domain

# Let's Encrypt Authorizations and Challenges
$auths = Get-PAOrder -Refresh -MainDomain $domain | Get-PAAuthorizations

# Let's Encrypt Notify the ACME Server
$auths.HTTP01Url | Send-ChallengeAck

New-PACertificate -Domain $domain -PfxPass $CertificatePassword -DNSSleep 10 -ValidationTimeout 20

<#
# Get certificate info
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($IssuedCertInfo.PfxFullChain,$CertificatePassword,'DefaultKeySet')
$cert | Format-List -Property *
#>
