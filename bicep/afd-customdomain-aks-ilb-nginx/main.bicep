param location string
param adminGroupObjectID string
param tags object
param k8sVersion string
param vmSku string
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string
param prefix string

var affix = uniqueString(resourceGroup().id)
var virtualNetworkName = 'vnet-${affix}'
var azureContainerRegistryName = 'acr${affix}'
var bastionName = 'bast-${affix}'

module azMonitorWorkspace 'modules/azureMonitor.bicep' = {
  name: 'azmon-module'
  params: {
    location: location
    prefix: prefix
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    prefix: prefix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module azureContainerRegistry './modules/acr.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    prefix: prefix
    isAdminUserEnabled: false
    isAnonymousPullEnabled: false
    isPublicNetworkAccessEnabled: 'Enabled'
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aks-module'
  dependsOn: [
    vnet
    azMonitorWorkspace
  ]
  params: {
    location: location
    prefix: prefix
    vnetName: vnet.outputs.vnetName
    logAnalyticsWorkspaceId: azMonitorWorkspace.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksServiceCIDR: '10.100.0.0/16'
    aksDnsPrefix: dnsPrefix
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    k8sVersion: k8sVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: azMonitorWorkspace.outputs.workspaceId
        }
      }
    }
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm-module'
  params: {
    location: location
    sshKey: sshPublicKey
    prefix: prefix
    subnetId: vnet.outputs.subnets[3].id
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    prefix: prefix
    location: location
    subnetId: vnet.outputs.subnets[5].id
  }
}

output aksClusterName string = aks.outputs.name
output bastionName string = bastion.outputs.name
