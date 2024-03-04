Param (
    [CmdletBinding()]
    [string]$AADTenant = 'kainiindustries.net',
    [string]$PublicDnsZone = 'kainiindustries.net',
    [string]$Prefix = 'test',

    [string]$ApiSvcIp = '1.1.1.1',
    [string]$Environment = 'dev',
    [string]$Semver = '0.1.2',
    [string]$ApiPort = "8081",
    [string]$ResourceGroupName = "$Environment-ag-apim-aks-rg",
    [string]$DeploymentName = "$Environment-infra-deployment"
)

$ErrorActionPreference = 'Stop'

$tenant = (Get-AzDomain $AADTenant)

# import custom PS module
Import-Module ./AppRegistration.psm1

# app regiatration definitions
$appRegistrationDefinitions = @(
    @{
        Name          = "$Prefix-$apiName-api"
        Type          = 'api'
        ApiDefinition = @{
            RequestedAccessTokenVersion = 2
            Oauth2PermissionScopes      = @(
                @{
                    Value                   = "$apiName.Read"
                    AdminConsentDisplayName = "Read $apiName API"
                    AdminConsentDescription = "Allows the app to read $apiName`s"
                    Id                      = (New-Guid).Guid
                    IsEnabled               = $True
                    Type                    = "Admin"
                    UserConsentDisplayName  = "read $apiName`s"
                    UserConsentDescription  = "allows app to read $apiName`s"
                },
                @{
                    Value                   = "$apiName.Write"
                    AdminConsentDisplayName = "Write $apiName API"
                    AdminConsentDescription = "Allows the app to write $apiName`s"
                    Id                      = (New-Guid).Guid
                    IsEnabled               = $True
                    Type                    = "Admin"
                    UserConsentDisplayName  = "write $apiName`s"
                    UserConsentDescription  = "allows app to write $apiName`s"
                }
            )
        }
        ApiRoles      = @(
            @{
                AllowedMemberTypes = @("User")
                Description        = "$apiName Reader Role"
                DisplayName        = "$apiName Reader Role"
                Id                 = (New-Guid).Guid
                IsEnabled          = $True
                Value              = "$apiName.Role.Read"
            },
            @{
                AllowedMemberTypes = @("User")
                Description        = "$apiName Writer Role"
                DisplayName        = "$apiName Writer Role"
                Id                 = (New-Guid).Guid
                IsEnabled          = $True
                Value              = "$apiName.Role.Write"
            }
        )
    }
)

# create AAD application registrations
Connect-MgGraph -TenantId $tenant.Id -Scopes "Application.ReadWrite.All"
$appRegistrations = New-AppRegistrations -AppRegistrations $appRegistrationDefinitions -TenantId $tenant.Id

# generate API policy XML documents
Write-Host -Object "Generating APIM policy XML file"
$xml = Get-Content .\api-policy-template.xml     

$xml -replace "{{APP_GWY_FQDN}}", "api.$PublicDnsZone" `
    -replace "{{AUDIENCE_API}}", $appRegistrations."$Prefix-$ApiName-api".AppId `
    -replace "{{SERVICE_URL}}", "http://$ApiSvcIp" `
    -replace "{{READ_ROLE_NAME}}", "$ApiName.Role.Read" `
    -replace "{{WRITE_ROLE_NAME}}", "$ApiName.Role.Write" `
    -replace "{{TENANT_NAME}}", $AADTenant > ./product-api-policy.xml

<# Write-Host -Object "Bulding container image"
az acr build -r $deployment.Outputs.acrName.value `
    -t $apiImageName `
    --build-arg SERVICE_PORT=$ApiPort `
    -f ../src/Dockerfile "../src/$ApiName" #>

<# # apply kubernetes manifests
Write-Host -Object "Applying Kubernetes manifests"
Import-AzAksCredential -ResourceGroupName $ResourceGroupName -Name $deployment.Outputs.aksClusterName.Value -Admin -Force

# create k8s namespace
kubectl apply -f ../manifests/namespace.yaml

# apply k8s manifest
$(Get-Content -Path "../manifests/$apiName.yaml") -replace "{{IMAGE_TAG}}", "$($deployment.Outputs.acrName.Value).azurecr.io/$apiImageName" -replace "{{SVC_IP_ADDRESS}}", $ApiSvcIp | kubectl apply -f -
 #>