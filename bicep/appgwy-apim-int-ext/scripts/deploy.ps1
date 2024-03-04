$certPassword = 'M1cr0soft123'
$location = 'australiaeast'
$domainName = 'kainiindustries.net'
$sqlPassword = 'M1cr0soft1234567890'
$sqlUserName = 'sqladmin'
$adminObjectId = '57963f10-818b-406d-a2f6-6e758d86e259'
$rgName = "ag-apim-func-api-$location-rg"
$sans = "api.$domainName", "portal.$domainName", "management.$domainName", "proxy.internal.$domainName", "portal.internal.$domainName", "management.internal.$domainName"
$zipName = 'funcapp.zip'
$winVmPassword = 'M1cr0soft1234567890'
$appName = 'todo-api-func'
$apiName = 'todo-api'

$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
$cerContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Cert

# create app registration for function app
if ((az ad sp list --all --query "[?displayName=='$appName']" | ConvertFrom-Json).Length -le 0) {
    Write-Host "Creating App Registration '$appName'"
    $sp = az ad sp create-for-rbac --name $appName | ConvertFrom-Json
    az ad app update --id $sp.appId --app-roles `@role.json
} else {
    $sp = az ad sp list --all --query "[?displayName=='$appName']" | ConvertFrom-Json
    az ad sp update --id $sp.id --set appRoleAssignmentRequired=False
}

# create certificate chain
$cert = @{}
$root = @{}
$securePassword = $certPassword | ConvertTo-SecureString -AsPlainText -Force

if (!($rootCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Root CA Certificate' }))) {
    Write-Host "Creating new Self-Signed CA Certificate"
    $rootCert = New-SelfSignedCertificate -CertStoreLocation 'cert:\CurrentUser\My' -TextExtension @("2.5.29.19={text}CA=true") -DnsName 'KainiIndustries CA' -Subject "SN=KainiIndustriesRootCA" -KeyUsageProperty All -KeyUsage CertSign, CRLSign, DigitalSignature -FriendlyName 'KainiIndustries Root CA Certificate'
}

$clearBytes = $rootCert.Export($cerContentType)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$root = @{CertName = $rootCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }

if (!($pfxCert = $(Get-ChildItem Cert:\CurrentUser\my | Where-Object { $_.friendlyName -eq 'KainiIndustries Client Certificate' }))) {
    Write-Host "Creating new Self-Signed Client Certificate"
    $pfxCert = New-SelfSignedCertificate -certstorelocation 'cert:\CurrentUser\My' -dnsname $sans -Signer $rootCert -FriendlyName 'KainiIndustries Client Certificate'
}

$clearBytes = $pfxCert.Export($pkcs12ContentType, $certPassword)
$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes)
$cert = @{CertName = $pfxCert.Thumbprint; CertValue = $fileContentEncoded; CertPassword = $certPassword }

# deploy bicep templates
$rg = New-AzResourceGroup -Name $rgName -Location $location -Force

New-AzResourceGroupDeployment `
    -Name 'apim-app-gwy-deploy' `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateParameterFile  ./main.parameters.json `
    -Mode Incremental `
    -templateFile ./main.bicep `
    -location $location `
    -domainName $domainName `
    -cert $cert `
    -rootCert $root `
    -winVmPassword $winVmPassword `
    -functionAppId $sp.appId `
    -sqlAdminUserPassword $sqlPassword `
    -sqlAdminUserName $sqlUserName `
    -adminObjectId $adminObjectId `
    -sqlDbName 'todosDb' `
    -Verbose

$deployment = Get-AzResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName -Name 'apim-app-gwy-deploy'

# compress funtion app code to .zip file
Compress-Archive -Path ./api/* -DestinationPath ./$zipName -Update

# deploy web app code as zip file
az webapp deployment source config-zip --resource-group $rg.ResourceGroupName --name $deployment.Outputs.funcAppName.Value --src ./$zipName

# import api from OpenApi definition
$apimContext = New-AzApiManagementContext -ResourceGroupName $rg.ResourceGroupName -ServiceName $deployment.Outputs.apimName.Value

if ($null -eq (Get-AzApiManagementApi -Context $apimContext -Name $apiName)) {
    Import-AzApiManagementApi -Context $apimContext `
        -ApiId $apiName `
        -SpecificationFormat OpenApi `
        -SpecificationPath ../api/api.yaml `
        -Path 'external' `
        -Protocol Https `
        -ServiceUrl $deployment.Outputs.funcAppUri.Value `
        -ApiType Http
}

# disable subscription requirement
$api = Get-AzApiManagementApi -Context $apimContext -Name $apiName
$api.SubscriptionRequired = $false
Set-AzApiManagementApi -InputObject $api -Name $api.Name -ServiceUrl $api.ServiceUrl -Protocols $api.Protocols

# add managed identity authnetication policy
$policyBody = "<policies><inbound><base /><authentication-managed-identity resource='$($sp.appId)'/></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>"
Set-AzApiManagementPolicy -Context $apimContext -ApiId $api.ApiId -Policy $policyBody -Verbose

# add the API Management Managed Identity to the funcion app's  'Todo.User' app role
# this will allow only the APIM Managed Identity to call the function app
az ad sp update --id $sp.objectId --set appRoleAssignmentRequired=True
$appObjectId = az ad sp show --id $sp.appid --query "objectId" -o tsv
 
@"
{"principalId":"$($deployment.Outputs.apimManagedIdentity.Value)","resourceId":"$appObjectId","appRoleId":"$($sp.appRoles[0].id)"}
"@ > ./body.json

az rest `
    --method POST `
    --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($deployment.Outputs.apimManagedIdentity.Value)/appRoleAssignments" `
    --headers 'Content-Type=application/json' --body "@body.json"


    https://func-bbowj45uj34aq.scm.azurewebsites.net
