param aksClusterName string
param location string
param aksUmidName string
param aksVersion string
param vmSku string
param maxPods int
param maxNodes int
param minNodes int
param linuxAdminUserName string
param sshPublicKey string
param vnetName string
param subnetName string
param workspaceId string
param aksWorkloadIdentityUmidName string
param keyVaultName string
param acrName string

var networkContributorRoleDefinitionId = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'
var acrPullRoleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = {
  name: acrName
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource aksUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aksUmidName
  location: location
}

resource aksWorkloadIdentityUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aksWorkloadIdentityUmidName
  location: location
}

resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksWorkloadIdentityUmid.id, 'keyVaultSecretsUserRole')
  scope: kv
  properties: {
    principalId: aksWorkloadIdentityUmid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinition', keyVaultSecretsUserRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksUmid.id, 'acrPullRole')
  scope: acr
  properties: {
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinition', acrPullRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

resource aksContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksUmid.id, contributorRoleDefinitionId, 'contributorRole')
  scope: resourceGroup()
  properties: {
    principalId: aksUmid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinition', contributorRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

resource aksNetworkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aksUmid.id, networkContributorRoleDefinitionId, 'networkContributorRole')
  scope: vnet
  properties: {
    principalId: aksUmid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinition', networkContributorRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' = {
  name: aksClusterName
  location: location
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksUmid.id}': {}
    }
  }
  properties: {
    serviceMeshProfile: {
      mode: 'Istio'
      istio: {
        components: {
          ingressGateways: [
            {
              enabled: true
              mode: 'Internal'
            }
          ]
        }
      }
    }
    kubernetesVersion: aksVersion
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: 1
        vmSize: vmSku
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        kubeletDiskType: 'OS'
        workloadRuntime: 'OCIContainer'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
        maxPods: maxPods
        type: 'VirtualMachineScaleSets'
        maxCount: maxNodes
        minCount: minNodes
        enableAutoScaling: true
        orchestratorVersion: aksVersion
        enableNodePublicIP: false
        enableCustomCATrust: false
        mode: 'System'
        enableEncryptionAtHost: false
        enableUltraSSD: false
        osType: 'Linux'
        osSKU: 'Ubuntu'
        upgradeSettings: {}
        enableFIPS: false
        networkProfile: {}
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUserName
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceId
          useAADAuth: 'true'
        }
      }
    }
    enableRBAC: true
    enablePodSecurityPolicy: false
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'Standard'
      serviceCidr: '192.168.8.0/22'
      dnsServiceIP: '192.168.8.8'
      outboundType: 'loadBalancer'
      serviceCidrs: [
        '192.168.8.0/22'
      ]
      ipFamilies: [
        'IPv4'
      ]
    }
    autoUpgradeProfile: {
      upgradeChannel: 'rapid'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    disableLocalAccounts: false
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
        version: 'v1'
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
  }
  dependsOn: [
    aksNetworkContributorRole
  ]
}

output clusterId string = aks.id
output clusterName string = aks.name
output clusterResourceGroup string = aks.properties.nodeResourceGroup
output workloadIdentityClientId string = aksWorkloadIdentityUmid.properties.clientId
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
output workloadManagedIdentityName string = aksWorkloadIdentityUmid.name
output workloadManagedIdentityId string = aksWorkloadIdentityUmid.id
