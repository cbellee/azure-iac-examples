param location string
param aksVersion string
param linuxAdminUserName string = 'azureuser'
param minNodes int = 1
param maxNodes int = 5
param maxPods int = 80
param vmSku string = 'Standard_D4ds_v5'
param sshPublicKey string
param aksSubnetName string = 'aks-subnet'
param vmSubnetName string = 'vm-subnet'
param addressPrefix string = '10.100.0.0/16'
param acrName string

var affix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${affix}'
var aksClusterName = 'cluster-${affix}'
var wksName = 'wks-${affix}'
var aksUmidName = 'aks-umid'
var wiUmidName = 'wi-umid'

resource aksUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: aksUmidName
  location: location
}

resource wiUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: wiUmidName
  location: location
}

module keyvault 'modules/kv.bicep' = {
  name: 'kv-module'
  params: {
    location: location
    secretName: 'mysecret'
    secretValue: sshPublicKey
    umidName: wiUmidName
  }
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
    vnetName: vnetName
    aksSubnetName: aksSubnetName
    vmSubnetName: vmSubnetName
    addressPrefix: addressPrefix
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
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
  }
}

output aksClusterName string = aks.outputs.clusterName
output oidcIssuerUrl string = aks.outputs.oidcIssuerUrl
output wiUmidClientId string = wiUmid.properties.clientId
output wiUmidName string = wiUmid.name
output secretName string = keyvault.outputs.secretName
output keyVaultUrl string = keyvault.outputs.keyVaultUrl
