param (
    [array]$AppRegistrationDefinitions
)

#Requires -Modules Microsoft.Graph.Applications

function New-ApiAppRegistration {
    Param (
        $Name,
        $ApiDefinition,
        $ApiRoles
    )
    
    if (!($appReg = $(Get-MgApplication -filter "DisplayName eq '$Name'"))) {
        Write-Host -Object "creating application '$($Name)'"
        $appReg = New-MgApplication `
            -DisplayName $Name `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Api $ApiDefinition `
            -AppRoles $ApiRoles `
            -Verbose

        Update-MgApplication -ApplicationId $appReg.Id -IdentifierUris "api://$($appReg.AppId)"
        New-MgServicePrincipal -AppId $appReg.AppId
    }
    else {
        Write-Host -Object "application '$($appReg.DisplayName)' already registered"
    }
    return $appReg
}

function New-ClientAppRegistration {
    Param (
        $Name,
        $RequiredResourceAccess
    )

    if (!($appReg = $(Get-MgApplication -filter "DisplayName eq '$Name'"))) {
        Write-Host -Object "creating application '$($Name)'"
        $appReg = New-MgApplication `
            -DisplayName $Name `
            -SignInAudience AzureADandPersonalMicrosoftAccount `
            -Spa @{ RedirectUris = $redirectUris } `
            -RequiredResourceAccess $RequiredResourceAccess `
            -Verbose

        New-MgServicePrincipal -AppId $appReg.AppId
    }
    else {
        Write-Host -Object "application '$($appReg.DisplayName)' already registered"
    }
    return $appReg
}

function New-AppRegistrations {

    Param(
        [string]$TenantId,
        [switch]$RemoveAppRegistrations,
        [array]$AppRegistrations
    )

    # Pre-requisites
    if ($null -eq (Get-Module -ListAvailable -Name "Microsoft.Graph.Applications")) {
        Install-Module "Microsoft.Graph.Applications" -Scope CurrentUser 
    }

    Import-Module Microsoft.Graph.Applications
    $ErrorActionPreference = "Stop"

    # connect to MS Graph API
    Write-Host "Connecting Microsoft Graph"
    Connect-MgGraph -TenantId $TenantId -Scopes "Application.ReadWrite.All"

    if ($RemoveAppRegistrations) {
        foreach ($appRegName in $AppRegistrations) {
            Write-Host -Object "Removing App Registration '$appRegName'"
            if ($($appReg = $(Get-MgApplication -filter "DisplayName eq '$appRegName'"))) {
                Write-Host -Object "Removing $appRegName App Registrations..."
                Remove-MgApplication -ApplicationId $appReg.Id
            }
            else {
                Write-Host -Object "App Registration '$appRegName' not found"
            }
        }
        return
    }

    $appRegDefinitions = @()
    $appRegHash = @{}

    # create api app registrations
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'api') {
        New-ApiAppRegistration -Name $appReg.Name -ApiDefinition $appReg.ApiDefinition -ApiRoles $appReg.ApiRoles
        $newAppReg = Get-MgApplication -Filter "DisplayName eq '$($appReg.Name)'"
        $appRegDefinitions += $newAppReg
        $appRegHash[$newAppReg.DisplayName] = $newAppReg
    }

    # define resource access
    $requiredResourceAccess = @(
        @{
            ResourceAppId  = $appRegDefinitions[0].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegDefinitions[0].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegDefinitions[0].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        },
        @{
            ResourceAppId  = $appRegDefinitions[1].AppId
            ResourceAccess = @(
                @{
                    Id   = $appRegDefinitions[1].Api.Oauth2PermissionScopes[0].Id
                    Type = "Scope"
                },
                @{
                    Id   = $appRegDefinitions[1].Api.Oauth2PermissionScopes[1].Id
                    Type = "Scope"
                }
            )
        }
    )

    # create spa app registration
    foreach ($appReg in $AppRegistrations | Where-Object Type -eq 'client') {
        $appReg.ResourceAccess = $requiredResourceAccess
        New-ClientAppRegistration -Name $appReg.Name -RequiredResourceAccess $appReg.ResourceAccess
        $newAppReg = Get-MgApplication -Filter "DisplayName eq '$($appReg.Name)'"
        $appRegHash[$newAppReg.DisplayName] = $newAppReg
    }

    $result = $appRegHash
    return $result
}

Export-ModuleMember -Function New-AppRegistrations
