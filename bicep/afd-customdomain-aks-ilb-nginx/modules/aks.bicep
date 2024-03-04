param location string
@description('Optional DNS suffix to use with hosted Kubernetes API server FQDN.')
param aksDnsPrefix string = 'aks'

param enableWorkloadIdentity bool = true
param enableOIDCIssuer bool = true
param vnetName string

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 30 to 1023.')
@minValue(30)
@maxValue(1023)
param aksAgentOsDiskSizeGB int = 250

@minValue(10)
@maxValue(250)
param maxPods int = 50

@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string = 'azure'

@description('The default number of agent nodes for the cluster.')
@minValue(1)
@maxValue(100)
param aksNodeCount int = 3

@minValue(1)
@maxValue(100)
@description('The minimum number of agent nodes for the cluster.')
param aksMinNodeCount int = 1

@minValue(1)
@maxValue(100)
@description('The minimum number of agent nodes for the cluster.')
param aksMaxNodeCount int = 10

@description('The size of the Virtual Machine.')
param aksNodeVMSize string = 'Standard_D4s_v3'

@description('The version of Kubernetes.')
param k8sVersion string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param aksServiceCIDR string = '10.100.0.0/16'

@description('Containers DNS server IP address.')
param aksDnsServiceIP string = '10.100.0.10'

@description('Enable RBAC on the AKS cluster.')
param aksEnableRBAC bool = true

param logAnalyticsWorkspaceId string
param enableAutoScaling bool = true
param aksSystemSubnetId string
param aksUserSubnetId string
param adminGroupObjectID string
param addOns object
param tags object
param enablePodSecurityPolicy bool = false
param enablePrivateCluster bool = false
param linuxAdminUserName string
param sshPublicKey string
param prefix string

var affix = uniqueString(resourceGroup().id)
var aksClusterName = '${prefix}-aks-${affix}'

var networkContributorRoleDefinitionGuid = '4d97b98b-1d4f-4787-a291-c67834d212e7'
var networkContributorRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${networkContributorRoleDefinitionGuid}'

var acrPullRoleDefinitionGuid = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPullRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionGuid}'

var kvAdminRoleIdDefinitionGuid = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var kvAdminRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${kvAdminRoleIdDefinitionGuid}'

var hasZones = pickZones('Microsoft.Compute', 'virtualMachines', location, 3)
var zones = [
  '1'
  '2'
  '3'
]

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-02-preview' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    oidcIssuerProfile: {
      enabled: enableOIDCIssuer
    }
    kubernetesVersion: k8sVersion
    enableRBAC: aksEnableRBAC
    enablePodSecurityPolicy: enablePodSecurityPolicy
    dnsPrefix: aksDnsPrefix
    addonProfiles: addOns
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    securityProfile: {
      workloadIdentity: {
        enabled: enableWorkloadIdentity
      }
    }
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
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        availabilityZones: !empty(hasZones) ? zones : null
        count: 1
        enableAutoScaling: true
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        maxPods: maxPods
        osDiskSizeGB: aksAgentOsDiskSizeGB
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSystemSubnetId
        tags: tags
        vmSize: aksNodeVMSize
        osDiskType: 'Ephemeral'
      }
      {
        name: 'linux'
        mode: 'User'
        availabilityZones: !empty(hasZones) ? zones : null
        osDiskSizeGB: aksAgentOsDiskSizeGB
        count: aksNodeCount
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        vmSize: aksNodeVMSize
        osType: 'Linux'
        osDiskType: 'Ephemeral'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksUserSubnetId
        enableAutoScaling: enableAutoScaling
        maxPods: maxPods
        tags: tags
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      serviceCidr: aksServiceCIDR
      dnsServiceIP: aksDnsServiceIP
      loadBalancerSku: 'standard'
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        adminGroupObjectID
      ]
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
} 

// Assign 'Network Contributor' role to AKS cluster system managed identity
resource aksNetworkContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, aksCluster.name, 'aksNetworkContributor')
  scope: vnet
  properties: {
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: networkContributorRoleId
    description: 'Assign Netowkr Contributor role to AKS cluster Managed Identity'
  }
}

// Assign 'AcrPull' role to AKS cluster kubelet identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, aksCluster.name, 'acrPull')
  properties: {
    principalId: aksCluster.properties.identityProfile.kubeletIdentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
    description: 'Assign AcrPull role to AKS cluster'
  }
}

// Assign 'KeyVault Administrator' role to AKS cluster KV CSI driver identity
resource kvAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, aksCluster.name, 'kvAdmin')
  properties: {
    principalId: aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: kvAdminRoleId
    description: 'Assign Keyvault Administrator role to AKS cluster secrets provider identity'
  }
}

resource aksDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: aksCluster
  name: 'aksDiagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
      }
      {
        category: 'guard'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}


output id string = aksCluster.id
output oidcIssuerUrl string = aksCluster.properties.oidcIssuerProfile.issuerURL
output name string = aksClusterName
output kubeletObjectId string = aksCluster.properties.identityProfile.kubeletIdentity.objectId
output aksClusterManagedIdentityObjectId string = aksCluster.identity.principalId
output aksNodeResourceGroupName string = aksCluster.properties.nodeResourceGroup
output hasZones array = hasZones
output zones array = zones
output resourceGroupName string = resourceGroup().name
output azureKeyvaultSecretsProviderClientId string = aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.clientId
output azureKeyvaultSecretsProviderResourceId string = aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId
