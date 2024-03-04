$location = 'australiaeast'
$resourceGroupName = 'app-svc-rg'
$dnsResourceGroupName = 'external-dns-zones-rg'
$deploymentName = 'app-gwy-app-svc-deployment'
$dnsDeploymentName = 'app-gwy-app-svc-dns-deployment'

# get pfx file content as a byte array & base64 encode it
$bytes = Get-Content -Path ./certs/gowebapp.kainiindustries.net/gowebapp.pfx -Encoding Byte
$base64Certificate = [System.Convert]::ToBase64String($bytes)

New-AzResourceGroup -Location $location -Name $resourceGroupName -Force

bicep build ./main.bicep
bicep build ./dns.bicep

$deploymentOutput = New-AzResourceGroupDeployment `
	-Name $deploymentName `
	-ResourceGroupName $resourceGroupName `
	-TemplateFile ./main.json `
	-TemplateParameterFile ./main.parameters.json `
	-pfxCertificate $base64Certificate

New-AzResourceGroupDeployment `
	-Name $dnsDeploymentName `
	-ResourceGroupName $dnsResourceGroupName `
	-TemplateFile ./dns.json `
	-TemplateParameterFile ./dns.parameters.json `
	-appGatewayFrontEndIpAddress $deploymentOutput.Outputs.appGatewayFrontEndIpAddress.Value
