param location string
param adminGroupObjectID string
param tags object
param prefix string
param aksVersion string = '1.30.0'
param vmSku string = 'Standard_F8s_v2'
param addressPrefix string
param subnets array
param sshPublicKey string
param secretName string

@secure()
param secretValue string

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
    retentionInDays: 30
  }
}

module keyVault 'modules/kv.bicep' = {
  name: 'kvDeploy'
  params: {
    location: location
    name: 'dev'
    tenantId: tenant().tenantId
    secretName: secretName
    secretValue: secretValue
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
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksServiceCIDR: '10.100.0.0/16'
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    k8sVersion: aksVersion
    vnetName: vnet.outputs.name
    enableOIDCIssuer: true
    enableWorkloadIdentity: true
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

output aksClusterName string = aks.outputs.name
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultId string = keyVault.outputs.keyVaultId
