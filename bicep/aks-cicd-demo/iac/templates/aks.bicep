param tags object
param location string
param aksSystemSubnetId string
param aksUserSubnetId string
param aksAdminGroupObjectId string
param aksVersion string
param azMonitorMworkspaceId string

var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPullRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionName}'
var networkContributorRoleDefinitionName = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var networkContributorRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${networkContributorRoleDefinitionName}'

// Azure Kubernetes Service
module aks '../modules/aks.bicep' = {
  name: 'module-aks'
  params: {
    location: location
    aksVersion: aksVersion
    zones: []
    tags: tags
    addOns: {}
    enablePrivateCluster: false
    aksSystemSubnetId: aksSystemSubnetId
    aksUserSubnetId: aksUserSubnetId
    logAnalyticsWorkspaceId: azMonitorMworkspaceId
    adminGroupObjectID: aksAdminGroupObjectId
  }
}

// Assign 'AcrPull' role to AKS cluster kubelet identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, aks.name, 'acrPullRoleAssignment')
  properties: {
    principalId: aks.outputs.aksKubeletIdentityObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
    description: 'Assign AcrPull role to AKS cluster'
  }
}

// Assign 'Network Contributor' role to AKS cluster system managed identity
resource aksNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, aks.name, 'aksNetworkContributorRoleAssignment')
  properties: {
    principalId: aks.outputs.aksClusterManagedIdentity
    principalType: 'ServicePrincipal'
    roleDefinitionId: networkContributorRoleId
    description: 'Assign Netowrk Contributor role to AKS cluster Managed Identity'
  }
}
