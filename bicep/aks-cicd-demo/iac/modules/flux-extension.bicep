param aksClusterName string
param gitRepoUrl string

@allowed([
  'dev'
  'test'
  'prod'
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
/*      infra: {
        path: './infrastructure'
        dependsOn: []
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        validation: 'none'
        prune: true
      } */
      apps: {
        path: './apps/${environmentName}'
        dependsOn: [
          /*{
            kustomizationName: 'infra'
          }*/
        ]
        timeoutInSeconds: 600
        syncIntervalInSeconds: 600
        retryIntervalInSeconds: 600
        prune: true
      }
    }
  }
}

