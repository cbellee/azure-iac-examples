[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("australiaeast", "australiasoutheast")]
    [String]
    $Location,

    [Parameter(Mandatory = $true)]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [String]
    $VnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $SubnetName,

    [Parameter(Mandatory = $true)]
    [String]
    $PublicIpName,

    [Parameter()]
    [Switch]
    $UpdateApim,

    [Parameter(Mandatory = $true)]
    [String]
    $ApimName,

    [Parameter(Mandatory = $true)]
    [String]
    $NsgName,

    [Parameter(Mandatory = $true)]
    [String]
    $DomainLabelPrefix
)

<#
.SYNOPSIS
    Script to deploy Bicep temaplate which updates a specific API Management Instance to use an External Public IP
.DESCRIPTION
    Script to deploy Bicep temaplate which updates a specific API Management Instance to use an External Public IP
    The deployment also creates a subnet in the specified vnet within the same resource group
.EXAMPLE
    Example test deployment whaivch shows only the potential changes - note the -WhatIf switch is specified when calling the script
    ./deploy.ps1 -location 'australiasoutheast' `
        -ResourceGroupName 'apim-pb-rg' `
        -VnetName 'apim-pb-vnet' `
        -SubnetName 'apim-subnet' `
        -PublicIpName 'apim-pip' `
        -ApimName 'apim-pb-inst' `
        -NsgName 'apim-nsg' `
        -DomainLabelPrefix 'cbellee-apim-external' `
        -WhatIf
.EXAMPLE
    Example deployment that adds the subnet & NSG, but skips changing APIM configuration
    ./deploy.ps1 -location 'australiasoutheast' `
        -ResourceGroupName 'apim-pb-rg' `
        -VnetName 'apim-pb-vnet' `
        -SubnetName 'apim-subnet' `
        -PublicIpName 'apim-pip' `
        -ApimName 'apim-pb-inst' `
        -NsgName 'apim-nsg' `
        -DomainLabelPrefix 'cbellee-apim-external' 
.EXAMPLE
    Example deployment that includes the change to APIM - note the '-UpdateApim' switch
    ./deploy.ps1 -location 'australiasoutheast' `
        -ResourceGroupName 'apim-pb-rg' `
        -VnetName 'apim-pb-vnet' `
        -SubnetName 'apim-subnet' `
        -PublicIpName 'apim-pip' `
        -ApimName 'apim-pb-inst' `
        -NsgName 'apim-nsg' `
        -DomainLabelPrefix 'cbellee-apim-external' `
        -UpdateApim 
#>

#Requires -Module @{ ModuleName = 'Az'; ModuleVersion = '5.6.0' }

if($WhatIfPreference.IsPresent) {$WhatIfPreference = $true}

New-AzResourceGroupDeployment `
    -Name 'apimExternalNetworkUpdateDeployment' `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile './main.bicep' `
    -UpdateApim $UpdateApim.IsPresent `
    -ApimName $ApimName `
    -PublicIpName $PublicIpName `
    -VnetName $VnetName `
    -SubnetName $SubnetName `
    -NsgName $NsgName `
    -DomainLabelPrefix $DomainLabelPrefix `
    -Verbose
