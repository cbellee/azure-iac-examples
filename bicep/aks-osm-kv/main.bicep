param location string
param adminGroupObjectID string
param tags object
param k8sVersion string = '1.25.2'
param vmSku string
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string
param uamiName string = 'akv-csi-workload-identity-uami'

var suffix = uniqueString(resourceGroup().id)

module uami './modules/user_assigned_identity.bicep' = {
  name: 'uami-module'
  params: {
    location: location
    name: uamiName
  }
}

module wks './modules/wks.bicep' = {
  name: 'wks-module'
  params: {
    suffix: suffix
    tags: tags
    location: location
    retentionInDays: 30
  }
}

module akv './modules/akv.bicep' = {
  name: 'akv-module'
  params: {
    suffix: suffix
    location: location
    adminObjectId: adminGroupObjectID
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    suffix: suffix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr './modules/acr.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    suffix: suffix
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aks-module'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    suffix: suffix
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
      /*
      openServiceMesh: {
        enabled: true
        config: {}
      }
      webApplicationRouting: {
        enabled: true
        config: {}
      } */
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

module akv_policy_secret_rotation 'modules/access_policy.bicep' = {
  name: 'secret-rotation-module'
  params: {
    keyVaultName: akv.outputs.name
    objectId: aks.outputs.aksSecretRotationIdentityObjectId
    permissions: {
      certificates: [
        'get'
        'list'
      ]
      keys: [
        'get'
        'list'
      ]
      secrets: [
        'get'
        'list'
      ]
    }
  }
}

module akv_policy_uami_workload_identity 'modules/access_policy.bicep' = {
  name: 'workload-identity-policy-module'
  params: {
    keyVaultName: akv.outputs.name
    objectId: uami.outputs.uamiPrincipalId
    permissions: {
      certificates: [
        'get'
        'list'
      ]
      keys: [
        'get'
        'list'
      ]
      secrets: [
        'get'
        'list'
      ]
    }
  }
}

output aksClusterName string = aks.outputs.aksClusterName
output aksClusterFqdn string = aks.outputs.aksControlPlaneFQDN
output aksClusterApiServerUri string = aks.outputs.aksApiServerUri
output keyVaultName string = akv.outputs.name
output uamiName string = uami.outputs.uamiName
output uamiClientId string = uami.outputs.uamiClientId
output uamiPrincipalId string = uami.outputs.uamiPrincipalId
output uamiTenantId string = uami.outputs.uamiTenantId
