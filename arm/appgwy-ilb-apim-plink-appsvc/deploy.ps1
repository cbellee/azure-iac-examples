[CmdletBinding()]
param (
	[Parameter()]
	[String]
	$ProjectName = 'appgwy-ilb-apim-plink-func',

	[Parameter()]
	[String]
	$ResourceGroupName = "$ProjectName-rg",

	[Parameter()]
	[String]
	$Location = 'australiaeast',

	[Parameter()]
	[HashTable]
	$Tags = @{"costCentre" = "478132"; "project" = "$projectName"},

	[Parameter()]
	[String]
	$ContainerName = 'nestedtemplates',

	[Parameter()]
	[String]
	$DomainName = 'kainiindustries.net',

	[Parameter()]
	[String]
	$KeyVaultUserObjectId = '57963f10-818b-406d-a2f6-6e758d86e259',

	[Parameter()]
	[String]
	$CertificateName = 'api-kainiindustries-net',

	[Parameter()]
	[String]
	$CertPassword = 'M1cr0soft1234567890'

)

function Set-PfxAsKeyVaultSecret {

	[CmdletBinding()]
	param (
		[Parameter()]
		[System.IO.Path]
		$PfxFilePath,

		[Parameter()]
		[System.IO.Path]
		$CertificatePassword,

		[Parameter()]
		[String]
		$SecretContentType = 'application/x-pkcs12',

		[Parameter()]
		[String]
		$KeyVaultName,

		[Parameter()]
		[String]
		$CertificateName
	)
	
	$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
	$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
	$collection.Import($PfxFilePath.FullName, $CertificatePassword, $flag)
	$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12
	$clearBytes = $collection.Export($pkcs12ContentType)
	$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
	$secret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText -Force
	Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $CertificateName -SecretValue $secret -ContentType $SecretContentType
}

$now = Get-Date
$sasTokenExpiry = $now.AddHours(2).ToString('u') -replace ' ', 'T'

New-AzResourceGroup -Location $location -Name $resourceGroupName -Force

$storageDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-storage-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './nestedtemplates/storage.json' `
	-ContainerName $containerName `
	-SasTokenExpiry $sasTokenExpiry

$keyVaultDeployment = New-AzResourceGroupDeployment `
	-Name "deploy-keyvault-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './nestedtemplates/keyvault.json' `
	-KeyVaultUserObjectId $keyVaultUserObjectId

<# 
$certPath = Get-Item "./certs/$CertificateName.pfx"

Set-PfxAsKeyVaultSecret -PfxFilePath $certPath `
	-CertificatePassword $certPassword `
	-KeyVaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-Verbose
 #>
 
# upload ARM template file to blob storage
az storage blob upload-batch -d $containerName -s ./nestedtemplates/ --pattern *.json --account-name $storageDeployment.Outputs.storageAccountName.value

New-AzResourceGroupDeployment `
	-Name "deploy-infra-$((Get-Date).ToFileTime())" `
	-ResourceGroupName $resourceGroupName `
	-Mode Incremental `
	-TemplateFile './azuredeploy.json' `
	-TemplateParameterFile './azuredeploy.parameters.json' `
	-StorageUri $storageDeployment.Outputs.storageContainerUri.value `
	-KeyVaultUri $keyVaultDeployment.Outputs.keyVaultUri.value `
	-KeyVaultName $keyVaultDeployment.Outputs.keyVaultName.value `
	-SasToken $storageDeployment.Outputs.storageAccountSasToken.value `
	-SslCertificateName $CertificateName `
	-ZoneName $domainName `
	-CName $("api.$domainName") `
	-Tags $tags `
	-Verbose
