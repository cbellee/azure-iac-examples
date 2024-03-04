$location = 'australiaeast'
$domainName = 'kainiindustries.net'
$rgName = "appgwy-e2e-ssl-rg"
$certPassword = 'M1cr0soft123'
$vmName = 'web-vm'
$winVmPassword
$keyVaultAdminUserObjectId = "57963f10-818b-406d-a2f6-6e758d86e259"
$pkcs12ContentType = 'Pkcs12'
$tags = @{
    'costcenter'='123456789'
    'environment'='devtest'
}

# create certificate chain
$secureCertPassword = $certPassword | ConvertTo-SecureString -AsPlainText -Force

# create root certificate
if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -NotBefore $(Get-Date).AddDays(-1) -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
} 

$rootCert = Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }

# create client certificate
if (!($clientCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $rootCert = Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate'}
    $clientCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -NotBefore $(Get-Date).AddDays(-1) -DnsName "web.$domainName" -Subject "web.$domainName" -Signer $rootCert -FriendlyName 'KainiIndustries Client Certificate'
}

$clientCert = Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }
Export-PfxCertificate -Password $secureCertPassword -FilePath ../certs/clientcert.pfx -Cert $clientCert
$clearBytes = $clientCert.Export($pkcs12ContentType, $certPassword)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$clientCertObject = @{CertName = 'client-cert'; CertThumbprint = $clientCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }

# create backend certificate
if (!($backendCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Backend Certificate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $rootCert = Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate'}
    $backendCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -NotBefore $(Get-Date).AddDays(-1) -DnsName "web-vm.internal.$domainName" -Subject "web-vm.internal.$domainName" -Signer $rootCert -FriendlyName 'KainiIndustries Backend Certificate'
}

$backendCert = Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Backend Certificate' }
Export-PfxCertificate -Password $secureCertPassword -FilePath ../certs/backendcert.pfx -Cert $backendCert
$clearBytes = $backendCert.Export($pkcs12ContentType, $certPassword)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$backendCertObject = @{CertName = 'backend-cert'; CertThumbprint = $backendCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }

Export-Certificate -FilePath ..\certs\root.cer -Cert $rootCert -Type CERT
certutil -encode -f ..\certs\root.cer ..\certs\base64root.cer
$base64CertFilePath = (Get-Item ..\certs\base64root.cer | Resolve-Path).ProviderPath
$rootCertObject =  @{CertName = 'root-cert'; CertThumbprint = $rootCert.Thumbprint; CertValue = [System.Convert]::ToBase64String($([System.IO.File]::ReadAllBytes($base64CertFilePath))); CertPassword = $certPassword }

# deploy bicep templates
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

$storageDeployment = New-AzResourceGroupDeployment `
    -Name 'storage-deployment' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../modules/storage.bicep `
    -ContainerName 'scripts'

# upload script to storage account
$storCtx = $(Get-AzStorageAccount -ResourceGroupName $rg.ResourceGroupName -Name $storageDeployment.outputs.storageAccountName.value).Context
Set-AzStorageBlobContent -File './iis.ps1' -Container $storageDeployment.outputs.containerName.value -Blob 'iis.ps1' -BlobType Block -Context $storCtx -Force | Out-Null

$kvDeployment = New-AzResourceGroupDeployment `
    -Name 'keyvault-deployment' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../modules/keyvault.bicep `
    -Tags $tags `
    -KeyVaultAdminObjectId $keyVaultAdminUserObjectId

# add certificates to KeyVault for App Gateway
Set-AzKeyVaultSecret -Name $rootCertObject.CertName -VaultName $kvDeployment.outputs.keyVaultName.value -SecretValue $($rootCertObject.CertValue | ConvertTo-SecureString -AsPlainText -Force) -ContentType 'application/x-pkcs12' | Out-Null
Set-AzKeyVaultSecret -Name $clientCertObject.CertName -VaultName $kvDeployment.outputs.keyVaultName.value -SecretValue $($clientCertObject.CertValue | ConvertTo-SecureString -AsPlainText -Force) -ContentType 'application/x-pkcs12' | Out-Null

# import pfx to KeyVault as certificate for backend VM
$backendCertProps = Import-AzKeyVaultCertificate -VaultName $kvDeployment.outputs.keyVaultName.value -Name 'backend-pfx-cert' -FilePath ../certs/backendcert.pfx -Password $secureCertPassword

New-AzResourceGroupDeployment `
    -Name 'appgwy-e2e-tls-deployment' `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -TemplateFile ../main.bicep `
    -Location $location `
    -DomainName $domainName `
    -Tags $tags `
    -ClientCert $clientCertObject `
    -RootCert $rootCertObject `
    -PfxSecretId $backendCertProps.SecretId `
    -PfxThumbprint $backendCertProps.Thumbprint `
    -ScriptUri "$($storageDeployment.Outputs.storageContainerUri.Value)" `
    -StorageAccountName $storageDeployment.outputs.storageAccountName.value `
    -DateTimeStamp (Get-Date).ToFileTime() `
    -WinVmPassword $winVmPassword `
    -VmName $vmName `
    -KeyVaultName $kvDeployment.outputs.keyVaultName.value `
    -Verbose
