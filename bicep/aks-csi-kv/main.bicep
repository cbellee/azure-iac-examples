param location string
param adminGroupObjectID string
param tags object
param prefix string
param aksVersion string = '1.23.3'
param vmSku string = 'Standard_F8s_v2'
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

module devKeyvault 'modules/kv.bicep' = {
  name: 'devKvDeploy'
  params: {
    location: location
    name: 'dev'
    tenantId: tenant().tenantId
  }
}

module uatKeyvault 'modules/kv.bicep' = {
  name: 'uatKvDeploy'
  params: {
    location: location
    name: 'uat'
    tenantId: tenant().tenantId
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
    location: location
    prefix: prefix
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
    adminGroupObjectID: adminGroupObjectID
    addOns: {
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

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
output devKeyVaultName string = devKeyvault.outputs.keyVaultName
output uatKeyVaultName string = uatKeyvault.outputs.keyVaultName
