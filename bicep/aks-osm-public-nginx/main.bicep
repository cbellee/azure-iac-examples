param location string
param adminGroupObjectID string
param tags object
param k8sVersion string
param vmSku string
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string

var suffix = uniqueString(resourceGroup().id)
var azureMonitorWorkspaceName = 'azmon-${suffix}'
var virtualNetworkName = 'vnet-${suffix}'
var azureContainerRegistryName = 'acr${suffix}'
var networkContributor = '4d97b98b-1d4f-4787-a291-c67834d212e7'

module azMonitorWorkspace 'modules/azureMonitor.bicep' = {
  name: 'azmon-module'
  params: {
    location: location
    name: azureMonitorWorkspaceName
  }
}

module vnet './modules/virtualNetwork.bicep' = {
  name: 'vnet-module'
  params: {
    name: virtualNetworkName
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module azureContainerRegistry './modules/azureContainerRegistry.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    name: azureContainerRegistryName
    tags: tags
  }
}

module aks './modules/azureKubernetesService.bicep' = {
  name: 'aks-module'
  dependsOn: [
    vnet
    azMonitorWorkspace
  ]
  params: {
    location: location
    suffix: suffix
    logAnalyticsWorkspaceId: azMonitorWorkspace.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksServiceCIDR: '10.100.0.0/16'
    aksDnsPrefix: dnsPrefix
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    k8sVersion: k8sVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      openServiceMesh: {
        enabled: true
        config: {}
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: azMonitorWorkspace.outputs.workspaceId
        }
      }
    }
  }
}

resource assign_NetworkContributor_to_kubelet 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(resourceGroup().id, aks.name, networkContributor)
  scope: resourceGroup()
  dependsOn: [
    aks
  ]
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', networkContributor)
    principalType: 'ServicePrincipal'
    principalId: aks.outputs.aksClusterManagedIdentityObjectId
  }
}

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
