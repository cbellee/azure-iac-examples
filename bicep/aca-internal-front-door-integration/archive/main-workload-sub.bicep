param location string = 'australiaeast'
param prefix string = 'contoso'
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param resourceGroupName string
param remoteSubscriptionId string

var vnetName = '${prefix}-workload-vnet'
var workspaceName = '${prefix}-wks'
var appName = '${prefix}-app'
var appEnvironmentName = '${prefix}-env'
var plsName = '${prefix}-pls'
var loadBalancerName = 'kubernetes-internal'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

module vnet 'modules/workload-vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'workoad-vnet-modules'
  params: {
    location: location
    vnetName: vnetName
  }
}

module workspace 'modules/wks.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'wks-module'
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module appEnvironment 'modules/appEnvironment.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'aca-env-module'
  params: {
    resourceGroupName: resourceGroupName
    appEnvironmentName: appEnvironmentName
    location: location
    vnetName: vnet.outputs.name
    workspaceName: workspace.outputs.name
    mTlsEnabled: false
  }
}

module containerApp 'modules/containerApp.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'container-app-module'
  params: {
    appName: appName
    environmentId: appEnvironment.outputs.id
    imageName: imageName
    location: location
  }
}

module privateLinkService './modules/pls.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'private-link-service-module'
  params: {
    location: location
    name: plsName
    remoteSubscriptionId: remoteSubscriptionId
    subscriptionId: subscription().subscriptionId
    appEnvironmentManagedResourceGroupName: appEnvironment.outputs.managedResourceGroupName
    loadBalancerName: loadBalancerName
    subnetId: vnet.outputs.subnets[1].id
  }
}

module afd 'modules/afd.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'afd-module'
  params: {
    containerAppFqdn: containerApp.outputs.fqdn
    location: location
    prefix: prefix
    privateLinkServiceId: privateLinkService.outputs.id
    subnetId: vnet.outputs.subnets[2].id
  }
}

output afdFqdn string = afd.outputs.afdFqdn
output privateLinkServiceName string = privateLinkService.outputs.name
output containerAppFqdn string = containerApp.outputs.fqdn
output managedResourceGroupName string = appEnvironment.outputs.managedResourceGroupName
output containerAppEnvironmentPrivateIpAddress string = appEnvironment.outputs.ipAddress
output vnetName string = vnet.outputs.name
