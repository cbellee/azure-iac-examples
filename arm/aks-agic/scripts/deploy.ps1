param(
    $location = 'australiaeast',
    $prefix = 'aks-appgwy-https-ingress'
)

$deploymentName = $('{0}-{1}-{2}' -f $prefix, 'deployment', (Get-Date).ToFileTime())
$rgName = "$prefix-rg"

$params = @{
    'virtualNetworkAddressPrefix'           = '10.0.0.0/8'
    'aksSubnetAddressPrefix'                = '10.0.0.0/16'
    'applicationGatewaySubnetAddressPrefix' = '10.1.0.0/16'
    'aksDnsPrefix'                          = 'aks'      
    'aksAgentOsDiskSizeGB'                  = 40
    'aksAgentCount'                         = 1
    'aksNodeVMSize'                         = 'Standard_F2s_v2'
    'kubernetesVersion'                     = '1.16.9'
    'aksEnableRBAC'                         = $true
    'applicationGatewaySku'                 = 'WAF_v2'
}

if (!(Get-AzResourceGroup -Name $rgName -Location $location -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rgName -Location $location
}

New-AzResourceGroupDeployment -Name $deploymentName `
    -ResourceGroupName $rgName `
    -Mode Incremental `
    -TemplateFile .\azuredeploy.json `
    -TemplateParameterObject $params `
    -Verbose
