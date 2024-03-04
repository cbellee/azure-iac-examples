param acrName string
param aksClusterName string

var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPullRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionName}'
var acrPullRoleAssignmentName = 'Microsoft.Authorization/${guid('${resourceGroup().id}acrPullRoleAssignment')}'

resource aksExisting 'Microsoft.ContainerService/managedClusters@2022-05-02-preview' existing = {
  name: aksClusterName
}

resource acrPullRoleAssignment 'Microsoft.ContainerRegistry/registries/providers/roleAssignments@2020-04-01-preview' = {
  name: '${acrName}/${acrPullRoleAssignmentName}'
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: reference(aksClusterName, '2020-12-01', 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}
