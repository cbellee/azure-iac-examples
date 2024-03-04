Param (
    [string]$AADTenant = 'kainiindustries.net',
    [string]$Prefix = 'test',
    [string]$ApiName
)

$tenant = (Get-AzDomain $AADTenant)

<#
$deploymentName = 'ag-apim-aks-deploy'
$keyVaultDeploymentName = 'kv-deploy'
#>

$redirectUris = @("http://localhost:3000", "https://api.$PublicDnsZone")

<# 
$environment = 'dev'
$semver = '0.1.2'
$tag = "$environment-$semver"
$spaImageName = "spa:$tag"
$orderApiImageName = "order:$tag"
$productApiImageName = "product:$tag"
$orderApiPort = "8080"
$productApiPort = "8081" 
#>

$ErrorActionPreference = 'stop'

# import custom PS module
Import-Module ./AppRegistration.psm1

# remove soft-deleted keyvault with same name
<# if ($DeleteKeyVaultInRemovedState) {
    Get-AzKeyVault -InRemovedState | Remove-AzKeyVault -InRemovedState -Force
}
 #>
# app regiatration definitions
$appRegistrationDefinitions = @(
    @{
        Name          = "$Prefix-order-api"
        Type          = 'api'
        ApiDefinition = @{
            RequestedAccessTokenVersion = 2
            Oauth2PermissionScopes      = @(
                @{
                    Value                   = "Order.Read"
                    AdminConsentDisplayName = "Read order API"
                    AdminConsentDescription = "Allows the app to read orders"
                    Id                      = (New-Guid).Guid
                    IsEnabled               = $True
                    Type                    = "Admin"
                    UserConsentDisplayName  = "read orders"
                    UserConsentDescription  = "allows app to read orders"
                },
                @{
                    Value                   = "Order.Write"
                    AdminConsentDisplayName = "Write order API"
                    AdminConsentDescription = "Allows the app to write orders"
                    Id                      = (New-Guid).Guid
                    IsEnabled               = $True
                    Type                    = "Admin"
                    UserConsentDisplayName  = "write orders"
                    UserConsentDescription  = "allows app to write orders"
                }
            )
        }
        ApiRoles      = @(
            @{
                AllowedMemberTypes = @("User")
                Description        = "Order Reader Role"
                DisplayName        = "Order Reader Role"
                Id                 = (New-Guid).Guid
                IsEnabled          = $True
                Value              = "Order.Role.Read"
            },
            @{
                AllowedMemberTypes = @("User")
                Description        = "Order Writer Role"
                DisplayName        = "Order Writer Role"
                Id                 = (New-Guid).Guid
                IsEnabled          = $True
                Value              = "Order.Role.Write"
            }
        )
    }
)

# calculate the first 3 IP addresses in 'AksLoadBalancerSubnet' for K8S services
<# $params = Get-Content ..\infra\main.parameters.json | ConvertFrom-Json
$aksLoadBalancerSubnetIp = $($params.parameters.vNets.value[1].subnets[2].addressPrefix -split '/')[0] -split '\.'
$first3Octets = $aksLoadBalancerSubnetIp[0], $aksLoadBalancerSubnetIp[1], $aksLoadBalancerSubnetIp[2] -join '.'
$orderApiSvcIp = $first3Octets, '4' -join '.'
$productApiSvcIp = $first3Octets, '5' -join '.'
$reactSpaSvcIp = $first3Octets, '6' -join '.'
 #>
<#  
# create resource group
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# create key vault & upload SSL certificate
Write-Host -Object "Deploying Key Vault"
New-AzResourceGroupDeployment `
    -Name $keyVaultDeploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -Mode Incremental `
    -templateFile ../infra/modules/keyvault.bicep `
    -keyVaultAdminObjectId $(Get-AzADUser -SignedIn | Select-Object -ExpandProperty Id) `
    -location $Location `
    -deployUserAccessPolicy $false

# get deployment output
$kvDeployment = Get-AzResourceGroupDeployment -Name $keyVaultDeploymentName -ResourceGroupName $rg.ResourceGroupName

# upload public tls certificate to Key Vault
Write-Host -Object "Uploading TLS certificate to Key Vault"
$tlsCertificate = Import-AzKeyVaultCertificate -VaultName $kvDeployment.Outputs.keyVaultName.value `
    -Name 'public-tls-certificate' `
    -Password $CertificatePassword `
    -FilePath ../certs/$PfxCertificateName
 #>
# create AAD application registrations
Connect-MgGraph -TenantId $tenant.Id -Scopes "Application.ReadWrite.All"
$appRegistrations = New-AppRegistrations -AppRegistrations $appRegistrationDefinitions -TenantId $tenant.Id

# patch react authConfig.json file 
<# Write-Host -Object "patching react 'authConfig.js' file"
$authConfig = Get-Content ../src/spa/src/authConfig_template.js
$authConfig `
    -replace "{{CLIENT_ID}}", $appRegistrations."$Prefix-react-spa".AppId `
    -replace "{{DOMAIN_NAME}}", $AADTenant `
    -replace "{{ORDER_READ}}", "$($appRegistrations."$Prefix-order-api".AppId)/$($appRegistrations."$Prefix-order-api".Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{ORDER_WRITE}}", "$($appRegistrations."$Prefix-order-api".AppId)/$($appRegistrations."$Prefix-order-api".Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{PRODUCT_READ}}", "$($appRegistrations."$Prefix-product-api".AppId)/$($appRegistrations."$Prefix-product-api".Api.Oauth2PermissionScopes[0].Value)" `
    -replace "{{PRODUCT_WRITE}}", "$($appRegistrations."$Prefix-product-api".AppId)/$($appRegistrations."$Prefix-product-api".Api.Oauth2PermissionScopes[1].Value)" `
    -replace "{{ORDER_API_ENDPOINT}}", "https://api.$PublicDnsZone/api/order/orders" `
    -replace "{{PRODUCT_API_ENDPOINT}}", "https://api.$PublicDnsZone/api/product/products" `
    -replace "{{REDIRECT_URI}}", "https://api.$PublicDnsZone" > ../src/spa/src/authConfig.js
 #>
# generate API policy XML documents
Write-Host -Object "Generating APIM policy XML file"
$xml = Get-Content .\api-policy-template.xml     

$xml -replace "{{APP_GWY_FQDN}}", "api.$PublicDnsZone" `
    -replace "{{AUDIENCE_API}}", $appRegistrations."$Prefix-$ApiName-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$orderApiSvcIp" `
    -replace "{{READ_ROLE_NAME}}", "Order.Role.Read" `
    -replace "{{WRITE_ROLE_NAME}}", "Order.Role.Write" `
    -replace "{{TENANT_NAME}}", $AADTenant > ./order-api-policy.xml

<# $xml -replace "{{APP_GWY_FQDN}}", "api.$PublicDnsZone" `
    -replace "{{AUDIENCE_API}}", $appRegistrations."$Prefix-product-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$productApiSvcIp" `
    -replace "{{READ_ROLE_NAME}}", "Product.Role.Read" `
    -replace "{{WRITE_ROLE_NAME}}", "Product.Role.Write" `
    -replace "{{TENANT_NAME}}", $AADTenant > ./product-api-policy.xml #>

# deploy bicep template
<# Write-Host -Object "Deploying infrastructure"
New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $rg.ResourceGroupName `
    -TemplateParameterFile  ../infra/main.parameters.json `
    -Mode Incremental `
    -templateFile ../infra/main.bicep `
    -location $Location `
    -publicDnsZoneName $PublicDnsZone `
    -publicDnsZoneResourceGroup $PublicDnsZoneResourceGroup `
    -privateDnsZoneName "internal.$PublicDnsZone" `
    -aksAdminGroupObjectId $AksAdminGroupObjectId `
    -kubernetesSpaIpAddress $reactSpaSvcIp `
    -orderApiYaml $(Get-Content -Raw -Path ../src/order/openapi.yaml) `
    -productApiYaml $(Get-Content -Raw -Path ../src/product/openapi.yaml) `
    -orderApiPoicyXml $(Get-Content -Raw -Path ./order-api-policy.xml) `
    -productApiPoicyXml $(Get-Content -Raw -Path ./product-api-policy.xml) `
    -keyVaultName $kvDeployment.Outputs.keyVaultName.value `
    -tlsCertSecretId $($tlsCertificate.SecretId | ConvertTo-SecureString -AsPlainText -Force) `
    -Verbose
#>

# get deployment output
<# $deployment = Get-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $rg.ResourceGroupName

# stop & start the app gateway for it to get the updated DNS zone!!!!
$appgwy = Get-AzApplicationGateway -Name $deployment.Outputs.appGwyName.value -ResourceGroupName $rg.ResourceGroupName

Write-Host -Object "Stopping App Gateway"
Stop-AzApplicationGateway -ApplicationGateway $appgwy

Write-Host -Object "Starting App Gateway"
Start-AzApplicationGateway -ApplicationGateway $appgwy
#>

<# # build container images in ACR
Write-Host -Object "Bulding Order container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $orderApiImageName `
    --build-arg SERVICE_PORT=$orderApiPort `
    -f ../src/Dockerfile ../src/order

Write-Host -Object "Bulding Product container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $productApiImageName `
    --build-arg SERVICE_PORT=$productApiPort `
    -f ../src/Dockerfile ../src/product

Write-Host -Object "Bulding Reaxt Spa container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $spaImageName `
    -f ../src/spa/Dockerfile ../src/spa

# apply kubernetes manifests
Write-Host -Object "Applying Kubernetes manifests"
Import-AzAksCredential -ResourceGroupName $rg.ResourceGroupName -Name $deployment.Outputs.aksClusterName.Value -Admin -Force

# create k8s namespace
kubectl apply -f ../manifests/namespace.yaml

# apply k8s manifests
$(Get-Content -Path ../manifests/order.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$orderApiImageName" -replace "{{SVC_IP_ADDRESS}}", $orderApiSvcIp | kubectl apply -f -
$(Get-Content -Path ../manifests/product.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$productApiImageName" -replace "{{SVC_IP_ADDRESS}}", $oproductApiSvcIp | kubectl apply -f -
$(Get-Content -Path ../manifests/spa.yaml) -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$spaImageName" -replace "{{SVC_IP_ADDRESS}}", $reactSpaSvcIp | kubectl apply -f -

# add admin consent for react spa app registration
az ad app permission admin-consent --id $appRegistrations."$Prefix-react-spa".AppId
 #>