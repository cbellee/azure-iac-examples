@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

param tags object
param location string
param vNets array
param aksAdminGroupObjectId string
param aksVersion string = '1.23.12'
param networkResourceGroupName string = 'demo-network-${environment}-rg'
param monitorResourceGroupName string = 'demo-monitor-${environment}-rg'
param workloadResourceGroupName string = 'demo-workload-${environment}-rg'

targetScope = 'subscription'

var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPullRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionName}'
var networkContributorRoleDefinitionName = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var networkContributorRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${networkContributorRoleDefinitionName}'

resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: networkResourceGroupName
}

resource monitorResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: monitorResourceGroupName
}

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  location: location
  name: workloadResourceGroupName
}

// Azure Monitor Workspace
module azMonitorModule '../modules/azmon.bicep' = {
  scope: resourceGroup(monitorResourceGroup.name)
  name: 'modules-azmon'
  params: {
    location: location
  }
}

// Virtual Networks
module vNetsModule '../modules/vnets.bicep' = [for (item, i) in vNets: {
  scope: resourceGroup(networkResourceGroup.name)
  name: 'module-vnet-${i}'
  params: {
    location: location
    vNet: item
    tags: tags
  }
}]

// Virtual Network Peering
module peeringModule '../modules/peering.bicep' = {
  scope: resourceGroup(networkResourceGroup.name)
  name: 'module-peering'
  params: {
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    vNetsModule
  ]
}

// Azure Container Registry
module acr '../modules/acr.bicep' = {
  scope: resourceGroup(workloadResourceGroupName)
  name: 'module-acr'
  params: {
    location: location
    tags: tags
  }
}

// Azure Kubernetes Service
module aks '../modules/aks.bicep' = {
  name: 'module-aks'
  scope: resourceGroup(workloadResourceGroup.name)
  params: {
    location: location
    aksVersion: aksVersion
    zones: []
    tags: tags
    addOns: {}
    enablePrivateCluster: false
    aksSystemSubnetId: vNetsModule[0].outputs.subnetRefs[0].id
    aksUserSubnetId: vNetsModule[0].outputs.subnetRefs[1].id
    logAnalyticsWorkspaceId: azMonitorModule.outputs.workspaceId
    adminGroupObjectID: aksAdminGroupObjectId
  }
}

// Assign 'AcrPull' role to AKS cluster kubelet identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(workloadResourceGroupName, aks.name, 'acrPullRoleAssignment')
  properties: {
    principalId: aks.outputs.aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
    description: 'Assign AcrPull role to AKS cluster'
  }
}

// Assign 'Network Contributor' role to AKS cluster system managed identity
resource aksNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(workloadResourceGroupName, aks.name, 'aksNetworkContributorRoleAssignment')
  properties: {
    principalId: aks.outputs.aksClusterManagedIdentity
    principalType: 'ServicePrincipal'
    roleDefinitionId: networkContributorRoleId
    description: 'Assign Netowrk Contributor role to AKS cluster Managed Identity'
  }
}

output acrName string = acr.outputs.registryName
output aksClusterName string = aks.outputs.aksClusterName

//output hubVnetRef string = vNetsModule[0].outputs.vnetRef
//output hubVnetName string = vNetsModule[0].outputs.vnetName
//output spokeVnetRef string = vNetsModule[1].outputs.vnetRef
//output spokeVnetName string = vNetsModule[1].outputs.vnetName
//output hubVnetSubnets array = vNetsModule[0].outputs.subnetRefs
//output spokeVnetSubnets array = vNetsModule[1].outputs.subnetRefs
