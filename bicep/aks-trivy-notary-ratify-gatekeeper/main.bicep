param location string
param adminGroupObjectID string
param tags object
param aksVersion string = ''
param vmSku string
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string
param currentUserPrincipalId string
param enableWorkloadIdentity bool = false

var suffix = uniqueString(resourceGroup().id)

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    suffix: suffix
    tags: tags
    location: location
  }
}

module kv 'modules/kv.bicep' = {
  name: 'kvDeploy'
  params: {
    suffix: suffix
    location: location
    principalId: currentUserPrincipalId
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    suffix: suffix
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
    suffix: suffix
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
    suffix: suffix
    acrName: acr.outputs.registryName
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
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
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    enableWorkloadIdentity: enableWorkloadIdentity
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
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
output keyVaultName string = kv.outputs.name
output keyVaultUri string = kv.outputs.uri
output acrName string = acr.outputs.registryName
output keyVaultId string = kv.outputs.id
