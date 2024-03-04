param location string
@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param aksDnsPrefix string = 'aks'

param zones array = []

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 30 to 1023.')
@minValue(30)
@maxValue(1023)
param aksAgentOsDiskSizeGB int = 30

@minValue(10)
@maxValue(250)
param maxPods int = 30

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
param aksVersion string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param aksServiceCIDR string = '10.100.0.0/16'

@description('Containers DNS server IP address.')
param aksDnsServiceIP string = '10.100.0.10'

@description('A CIDR notation IP for Docker bridge.')
param aksDockerBridgeCIDR string = '172.17.0.1/16'

@description('Enable RBAC on the AKS cluster.')
param aksEnableRBAC bool = true

param logAnalyticsWorkspaceId string
param enableAutoScaling bool = true
param aksSystemSubnetId string
param aksUserSubnetId string
param prefix string
param adminGroupObjectID string
param addOns object
param tags object
param enablePodSecurityPolicy bool = false
param enablePrivateCluster bool = false

var aksClusterName = 'aks-${prefix}'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-06-02-preview' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: aksVersion
    enableRBAC: aksEnableRBAC
    enablePodSecurityPolicy: enablePodSecurityPolicy
    dnsPrefix: aksDnsPrefix
    addonProfiles: addOns
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        availabilityZones: zones
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
        availabilityZones: zones
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
      dockerBridgeCidr: aksDockerBridgeCIDR
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

resource aksDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: aksCluster
  name: 'aksDiagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'kube-audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'kube-audit-admin'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'kube-controller-manager'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'kube-scheduler'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
      {
        category: 'guard'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

output aksFqdn string = enablePrivateCluster ? aksCluster.properties.privateFQDN : aksCluster.properties.fqdn
output aksClusterName string = aksCluster.name
output aksKubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletIdentity.objectId
output aksResourceId string = aksCluster.id
output aksClusterManagedIdentity string = aksCluster.identity.principalId
