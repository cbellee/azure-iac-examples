param aksClusterName string
param gitRepoUrl string

@allowed([
  'staging'
  'production'
])
param environmentName string

resource aks 'Microsoft.ContainerService/managedClusters@2023-08-02-preview' existing = {
  name: aksClusterName
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2023-05-01' = {
  name: 'cluster-config'
  scope: aks
  dependsOn: [
    fluxExtension
  ]
  properties: {
    scope: 'cluster'
    namespace: 'cluster-config'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: gitRepoUrl
      timeoutInSeconds: 600
      syncIntervalInSeconds: 600
      repositoryRef: {
        branch: 'main'
      }

    }
    kustomizations: {
      'infra': {
        path: './infrastructure'
        syncIntervalInSeconds: 120
      }
      'apps': {
        path: './apps/${environmentName}'
        syncIntervalInSeconds: 120
        dependsOn: [
          'infra'
        ]
      }
    }
  }
}
