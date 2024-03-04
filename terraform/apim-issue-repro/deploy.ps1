$certPassword = 'M1cr0soft123'
$domainName = 'kainiindustries.net'
$rgName = 'apim-test-rg'
$sans = "api.$domainName", "apim.$domainName", "apim-proxy.$domainName", "developer.apim.$domainName", "portal.apim$domainName", "management.apim.$domainName", "proxy.internal.$domainName", "portal.internal.$domainName", "management.internal.$domainName"
$sans2 = "apim-proxy.internal.$domainName"

# create certificate chain
$securePassword = $certPassword | ConvertTo-SecureString -AsPlainText -Force

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed Root CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
    Export-Certificate -Cert $rootcert -FilePath .\certs\rootCert.cer -Force
}

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certififcate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certififcate'
    Export-PfxCertificate -cert $pfxCert -FilePath .\certs\clientCert.pfx -Password $securePassword -CryptoAlgorithmOption TripleDES_SHA1 -Force
}

if (!($pfxCert2 = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certififcate 2' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert2 = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans2 -Signer $rootCert -FriendlyName 'KainiIndustries Client Certififcate 2'
    Export-PfxCertificate -cert $pfxCert2 -FilePath .\certs\clientCert2.pfx -Password $securePassword -CryptoAlgorithmOption TripleDES_SHA1 -Force
}

$env:TF_LOG="DEBUG"
$env:TF_LOG_PATH="./debug_log.json"

terraform init
terraform plan -var apim_cert_password=$certPassword -out=tfplan -var domain_name=$domainName -var rg_name=$rgName
terraform apply tfplan
