Param(
    [Parameter(mandatory)]
    [string]
    $SubscriptionId,

    [string]
    $Prefix = 'aks-cli-test',

    [string]
    $Location = 'australiaeast',

    [string]
    $AKSClusterName = 'aks-cli-test',

    [string]
    $VMSize = 'Standard_F2s_v2',

    [string]
    $NodeCount = 1,

    [string]
    $MinNodeCount = 1,

    [string]
    $MaxNodeCount = 5,

    [string]
    $KubernetesVersion = '1.16.9',

    [Parameter(mandatory)]
    [string]
    $SshPublicKey
)

$resourceGroupName = "$Prefix-rg"
$vnetAddressPrefixes = '10.0.0.0/8'
$subnetPrefix = '10.240.0.0/16'
$serviceCIDR = '10.0.0.0/16'
$dockerBridgeCIDR = '172.17.0.1/16'
$dnsServiceIp = '10.0.0.10'
$loadBalancerManagedOutboundIpCount = 2
$maxPods = 50

$account = az account show | ConvertFrom-Json

if ($account.id -ne $subscriptionId) {
    az account set --subscription $SubscriptionId
}

<#
    # enable preview 'MSIPreview' feature
    az feature register --name MSIPreview --namespace Microsoft.ContainerService
    az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/MSIPreview')].{Name:name,State:properties.state}"
    az provider register -n Microsoft.ContainerService
#>

# create resource group
$rg = az group create --name $ResourceGroupName --location $Location | ConvertFrom-Json

# create public IPs
$publicOutboundIps = 1..$loadBalancerManagedOutboundIpCount | ForEach-Object {
    az network public-ip create `
        --resource-group $rg.name `
        --name "$Prefix-pip-$_" `
        --location $Location `
        --version IPv4 `
        --sku Standard | ConvertFrom-Json
}

$wksJson = '{\"sku\":{\"Name\":\"PerGB2018\"}}'

# create LA workspace
$workspace = az resource create `
    --resource-group $rg.name `
    --resource-type Microsoft.OperationalInsights/workspaces `
    --name "$Prefix-wks" `
    --location $Location `
    --properties $wksJson | ConvertFrom-Json

# create vnet & subnets
$vnet = az network vnet create `
    --name "$Prefix-vnet-1" `
    --resource-group $rg.name `
    --location $Location `
    --address-prefixes $vnetAddressPrefixes | ConvertFrom-Json

$subnet = az network vnet subnet create `
    --resource-group $rg.name `
    --vnet-name $vnet.newVNet.name `
    --address-prefixes $subnetPrefix `
    --name "$Prefix-subnet-1" | ConvertFrom-Json

# create ACR
$acr = az acr create `
    --name "$($prefix.Replace('-',''))acr" `
    --sku Standard `
    --admin-enabled true `
    --resource-group $rg.name `
    --location $Location | ConvertFrom-Json

# create AKS
$aks = az aks create `
    --resource-group $rg.name `
    --name $AKSClusterName `
    --ssh-key-value $sshPublicKey `
    --kubernetes-version $KubernetesVersion `
    --enable-managed-identity `
    --node-vm-size $VMSize `
    --nodepool-name 'pool1' `
    --node-count $NodeCount `
    --enable-vmss `
    --vm-set-type 'VirtualMachineScaleSets' `
    --network-plugin 'Azure' `
    --enable-cluster-autoscaler `
    --min-count $MinNodeCount `
    --max-count $MaxNodeCount `
    --docker-bridge-address $dockerBridgeCIDR `
    --dns-service-ip $dockerBridgeCIDR `
    --service-cidr $serviceCIDR `
    --dns-service-ip $dnsServiceIp `
    --load-balancer-sku 'Standard' `
    --load-balancer-outbound-ips $($publicOutboundIps.publicIp.id -join ',') `
    --enable-addons monitoring `
    --workspace-resource-id $workspace.Id `
    --vnet-subnet-id $subnet.id `
    --max-pods $maxPods `
    --attach-acr $acr.id

$aks



