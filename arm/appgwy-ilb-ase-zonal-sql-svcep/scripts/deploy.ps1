param(
	#[Parameter(Mandatory)]
	[string]
	$Location = 'australiaeast',

	#[Parameter(Mandatory)]
	[string]
	$Prefix = 'appgwy-ilb-ase-zonal',

	#[Parameter(Mandatory)]
	[string]
	$DomainName = 'kainiindustries.net',

	[string]
	$DnsResourceGroupName = 'external-dns-zones-rg',

	[string]
	$DbUserName = 'dbadmin',

	#[Parameter(Mandatory)]
	[string]
	$DbAdminPassword = 'M1cr0soft1234567890'
)

$ProgressPreference = 'Continue'

$resourceGroupName = "$prefix-rg"
$certificateName = "api.$DomainName"
$containerName = 'nestedtemplates'

# get executing user's mail & objectId to add to keyvault access policy 
$ctx = Get-AzContext
$keyVaultUserEmailAddress = (Get-AzADUser -Mail $ctx.Account).Mail
$keyVaultUserObjectId = (Get-AzADUser -Mail $ctx.Account).Id

# create resource group
if (!($rg = Get-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction SilentlyContinue)) {
	$rg = New-AzResourceGroup -Name $resourceGroupName -Location $location -Verbose
}

# deploy storage account to hold child ARM templates
$sasTokenExpiry = (Get-Date).AddHours(2).ToString('u') -replace ' ', 'T'
$storageDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-storage" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\nestedtemplates\storage.json `
	-ContainerName $containerName `
	-SasTokenExpiry $sasTokenExpiry `
	-Verbose

# upload ARM template files to blob storage account
$sa = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageDeployment.Outputs.storageAccountName.Value
Get-ChildItem $PSScriptRoot\..\nestedtemplates -File | ForEach-Object {
	Set-AzStorageBlobContent `
		-File $_.FullName `
		-Context $sa.Context `
		-Container $containerName `
		-Blob $_.Name `
		-BlobType Block `
		-Force 
}

# deploy key vault to store app gateway ssl certificate 
$keyVaultDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-keyvault" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\nestedtemplates\keyvault.json `
	-KeyVaultUserObjectId $keyVaultUserObjectId `
	-Verbose

<# $keyVaultDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-keyvault'
$storageDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-storage'
$resourceDeployment = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name 'deploy-ase-db'
#>

$templateParams = @{
	storageUri      = $storageDeployment.Outputs.storageContainerUri.value
	sasToken        = $storageDeployment.Outputs.storageAccountSasToken.value
	dbAdminLogin    = $DbUserName
	dbAdminPassword = $DbAdminPassword
	aseZones        = @('1', '2')
}

# deploy nsg, vnet, 2 x ase & mySql flexible server, 
$resourceDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-ase-db" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\azuredeploy-1.json `
	-TemplateParameterFile $PSScriptRoot\..\azuredeploy-1.parameters.json `
	@templateParams `
	-Verbose

# get internal Load Balancer (ILB) App Service Environment (ASE) site fqdns
# create temaplte parameter input array object
$appGwyApp = @{name = 'test-site'; hostName = $certificateName; backendAddresses = @(); backends = @(); probePath = '/'; }

$i = 0
while ($i -lt $resourceDeployment.Outputs.aseHostingEnvironmentIds.Value.Count) {
	$appGwyApp.backendAddresses += @{fqdn = $($resourceDeployment.Outputs.siteFqdns.Value[$i].value) }
	$aseId = $resourceDeployment.Outputs.aseHostingEnvironmentIds.Value[$i].value
	$aseIp = az resource show --ids "$aseId/capacities/virtualip" --query internalIpAddress --output tsv --api-version 2018-02-01

	$appGwyApp.backends += @{
		asefqdn   = $($resourceDeployment.Outputs.aseFqdns.Value[$i].value)
		sitename  = $($resourceDeployment.Outputs.siteNames.Value[$i].value)
		asevnetid = $($resourceDeployment.Outputs.aseVnetIds.Value[$i].value)
		ip        = $aseIp
	}

	$i++
}

# create self-signed ssl certificate in key vault
$policy = New-AzKeyVaultCertificatePolicy -ValidityInMonths 12 `
	-SubjectName "CN=$certificateName" `
	-IssuerName self `
	-RenewAtNumberOfDaysBeforeExpiry 30

$certificateName = $($certificateName -replace '\.', '-') + '-1'

Set-AzKeyVaultAccessPolicy -VaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-EmailAddress $keyVaultUserEmailAddress `
	-PermissionsToCertificates create, get, list

$certificate = Add-AzKeyVaultCertificate -VaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-Name $certificateName `
	-CertificatePolicy $policy

$sleepInterval = 5
while ($null -eq ($certificate = Get-AzKeyVaultCertificate -VaultName $keyVaultDeployment.Outputs.keyVaultName.value -Name $certificateName)) {
	Write-Host "Sleeping '$sleepInterval' seconds until certificate becomes available..."
	Start-Sleep -Seconds $sleepInterval
}

$secretId = $certificate.SecretId.Replace($certificate.Version, "")

$templateParams = @{
	StorageUri         = $storageDeployment.Outputs.storageContainerUri.value
	SasToken           = $storageDeployment.Outputs.storageAccountSasToken.value
	SubnetId           = $resourceDeployment.outputs.appGatewaySubnetId.value
	KeyVaultName       = $keyVaultDeployment.outputs.keyVaultName.value
	AppGwyApplications = $appGwyApp
	CertificateId      = $secretId
}

# deploy application gateway, private DNS zones & DNS records
$appGwyDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-app-gateway" `
	-ResourceGroupName $rg.ResourceGroupName `
	-Mode Incremental `
	-TemplateFile $PSScriptRoot\..\azuredeploy-2.json `
	-TemplateParameterFile $PSScriptRoot\..\azuredeploy-2.parameters.json `
	@templateParams `
	-Verbose
	
# add Azure DNS alias for App Gateway public ip address resource (this will only work if the Azure DNS zone already exists & name is specified in script arguments)
if ($null -ne $DnsResourceGroupName) {
	$templateParams = @{
		zoneName          = $DomainName
		dnsName           = 'api'
		publicIpAddressId = $appGwyDeployment.Outputs.appGatewayPublicIpAddressId.value
	}

	$publicDnsDeployment = New-AzResourceGroupDeployment `
		-Name "deploy-public-dns-alias" `
		-ResourceGroupName $DnsResourceGroupName `
		-Mode Incremental `
		-TemplateFile $PSScriptRoot\..\nestedtemplates\dns.json `
		@templateParams `
		-Verbose

	$publicDnsDeployment.Outputs.url.value
}
