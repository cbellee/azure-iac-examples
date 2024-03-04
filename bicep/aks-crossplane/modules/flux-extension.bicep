param aksClusterName string
param gitRepoUrl string

@allowed([
  'staging'
  'production'
])
param environmentName string

resource aks 'Microsoft.ContainerService/managedClusters@2022-01-02-preview' existing = {
  name: aksClusterName
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2021-09-01' = {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
  }
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2021-11-01-preview' = {
  name: 'flux-system'
  scope: aks
  dependsOn: [
    fluxExtension
  ]
  properties: {
    scope: 'cluster'
    namespace: 'flux-system'
    sourceKind: 'GitRepository'
    suspend: false
    gitRepository: {
      url: gitRepoUrl
      timeoutInSeconds: 300
      syncIntervalInSeconds: 300
      repositoryRef: {
        branch: 'main'
      }
    }
    kustomizations: {
      infra: {
        path: './bicep/aks-crossplane/infrastructure'
        dependsOn: []
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        validation: 'none'
        prune: true
      }
      apps: {
        path: './bicep/aks-crossplane/apps/${environmentName}'
        dependsOn: [
          {
            kustomizationName: 'infra'
          }
        ]
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
    }
  }
}
