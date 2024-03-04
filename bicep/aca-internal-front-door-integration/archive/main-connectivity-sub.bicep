param location string
param prefix string = 'contoso'
param remoteSubscriptionId string
param resourceGroupName string
param appEnvironmentResourceGroupName string
param workloadVnetName string

var connectivityVnetName = '${prefix}-connectivity-vnet'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

resource workloadVnet 'Microsoft.ScVmm/virtualNetworks@2022-05-21-preview' existing = {
  name: workloadVnetName
  scope: resourceGroup(appEnvironmentResourceGroupName)
}

module vnet './modules/connectivity-vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnet-module'
  params: {
    vnetName: connectivityVnetName
    location: location
  }
}

module peering_local_to_remote './modules/vnet-peering.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'local-to-remote-peering-module'
  params: {
    localVnetName: vnet.outputs.name
    remoteVnetName: workloadVnet.name
    remoteResourceGroupName: appEnvironmentResourceGroupName
    remoteSubscriptionId: remoteSubscriptionId
  }
}

module peering_remote_to_local './modules/vnet-peering.bicep' = {
  scope: resourceGroup(remoteSubscriptionId, appEnvironmentResourceGroupName)
  name: 'remote-to-local-peering-module'
  params: {
    localVnetName: workloadVnet.name 
    remoteVnetName: vnet.outputs.name
    remoteResourceGroupName: rg.name
    remoteSubscriptionId: subscription().subscriptionId
  }
}
