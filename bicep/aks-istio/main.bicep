param location string = 'australiaeast'
param aksVersion string = '1.27.1'
param linuxAdminUserName string = 'azureuser'
param minNodes int = 1
param maxNodes int = 3
param maxPods int = 80
param vmSku string = 'Standard_D4ds_v5'
param sshPublicKey string
param aksSubnetName string = 'k8s-subnet'
param appGatewaySubnetName string = 'gwy-subnet'
param vmSubnetName string = 'vm-subnet'
param aksSubnetAddressPrefix string = '192.168.0.0/24'
param appGatewaySubnetAddressPrefix string = '192.168.1.0/24'
param vmSubnetAddressPrefix string = '192.168.2.0/24'
param acrName string

var affix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${affix}'
var aksClusterName = 'cluster-${affix}'
var wksName = 'wks-${affix}'
var aksUmidName = 'aks-umid'

resource aksUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksUmidName
  location: location
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
    vnetName: vnetName
    aksSubnetName: aksSubnetName
    appGatewaySubnetName: appGatewaySubnetName
    vmSubnetName: vmSubnetName
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    appGatewaySubnetAddressPrefix: appGatewaySubnetAddressPrefix
    vmSubnetAddressPrefix: vmSubnetAddressPrefix
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: wksName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks-module'
  params: {
    acrName: acrName
    aksClusterName: aksClusterName
    aksUmidName: aksUmidName
    aksVersion: aksVersion
    linuxAdminUserName: linuxAdminUserName
    location: location
    maxNodes: maxNodes
    maxPods: maxPods
    minNodes: minNodes
    sshPublicKey: sshPublicKey
    vmSku: vmSku
    vnetName: vnet.outputs.name
    subnetName: vnet.outputs.aksSubnetName
    workspaceId: wks.id
    aksWorkloadIdentityUmidName: 'aks-workload-identity-umid'
  }
}

output aksClusterName string = aks.outputs.clusterName
output workloadIdentityClientId string = aks.outputs.workloadIdentityClientId
output oidcIssuerUrl string = aks.outputs.oidcIssuerUrl
output workloadManagedIdentityName string = aks.outputs.workloadManagedIdentityName
output workloadManagedIdentityId string = aks.outputs.workloadManagedIdentityId
