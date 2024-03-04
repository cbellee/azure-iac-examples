param location string
param adminGroupObjectID string
param tags object
param environment string
param aksVersion string = '1.6.0'
param vmSku string = 'Standard_F8s_v2'
param addressPrefix string
param subnets array
param sshPublicKey string
param gitRepoUrl string
param deployFluxConfig bool = false

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    prefix: environment
    tags: tags
    location: location
    retentionInDays: 30
  }
}

module kv './modules/kv.bicep' = {
  name: 'kvDeploy'
  params: {
    prefix: environment
    tags: tags
    location: location
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    prefix: environment
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    location: location
    prefix: environment
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    prefix: environment
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksDnsPrefix: environment
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
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      azureKeyVaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '120s'
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

module flux_extension 'modules/flux-extension.bicep' = if (deployFluxConfig) {
  name: 'fluxDeploy'
  params: {
    aksClusterName: aks.outputs.aksClusterName
    gitRepoUrl: gitRepoUrl
    environmentName: environment
  }
}

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
output keyVaultName string = kv.outputs.name
output keyVaultId string = kv.outputs.id
