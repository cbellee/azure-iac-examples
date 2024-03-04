Param (
    [CmdletBinding()]
    [string]$AADTenant,
    [string]$PublicDnsZone,
    [string]$Prefix,
    [string]$ApiName
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

$appRegistrationId = $appRegistrations."$Prefix-$ApiName-api".AppId
$appReadRoleName = "$ApiName.Role.Read"
$appWriteRoleName = "$ApiName.Role.Write"

# set variables for next pipeline step
Write-Host "##vso[task.setvariable variable=appRegistrationId;]$appRegistrationId"
Write-Host "##vso[task.setvariable variable=appReadRoleName;]$appReadRoleName"
Write-Host "##vso[task.setvariable variable=appWriteRoleName;]$appWriteRoleName"
