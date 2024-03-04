param environment string
param aksClusterName string
param gitRepoUrl string
param resourceGroupName string

resource existingAksCluster 'Microsoft.ContainerService/managedClusters@2022-08-03-preview' existing = {
  name: aksClusterName
  scope: resourceGroup(resourceGroupName)
}

module flux_extension '../modules/flux-extension.bicep' = {
  name: 'fluxDeploy'
  params: {
    aksClusterName: existingAksCluster.name
    gitRepoUrl: gitRepoUrl
    environmentName: environment
  }
}
