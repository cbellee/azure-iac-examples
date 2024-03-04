@allowed([
  'australiaeast'
  'australiasoutheast'
])
param location string
param adminGroupObjectId string
param tags object
param prefix string
param aksVersion string = '1.28.3'
param vmSku string = 'Standard_D4ds_v5'
param addressPrefix string
param subnets array
param sshPublicKey string

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
    retentionInDays: 30
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    prefix: prefix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
  }
}

/* module afd 'modules/afd.bicep' = {
  name: 'afdDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
  }
} */

module aks './modules/aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    umidName: 'aks-pls-umid'
    vnetName: vnet.outputs.name
    prefix: prefix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksDnsPrefix: prefix
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksServiceCIDR: '10.100.0.0/16'
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: 'localadmin'
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectId
    addOns: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
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
          logAnalyticsWorkspaceResourceID: wks.outputs.workspaceId
        }
      }
    }
  }
}

output aks_cluster_name string = aks.outputs.aksClusterName
