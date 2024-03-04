@description('location to deploy the storage account')
param location string

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param aksDnsPrefix string = 'aks'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 30 to 1023.')
@minValue(30)
@maxValue(1023)
param aksNodeOsDiskSizeGB int = 40

@description('CNI plugin \'kubenet\' or \'azure\'')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string = 'azure'

@description('The default number of agent nodes for the cluster.')
@minValue(1)
@maxValue(50)
param aksNodeCount int = 1
param enableAutoScaling bool = true

@description('The minimum number of agent nodes for the cluster.')
@minValue(1)
@maxValue(50)
param aksMinNodeCount int = 1

@description('The maximum number of agent nodes for the cluster.')
@minValue(1)
@maxValue(50)
param aksMaxNodeCount int = 5

@description('The maximum number of pods per AKS worker node')
param maxPods int = 30

@description('The size of the Virtual Machine.')
@allowed([
  'Standard_D4ds_v5'
  'Standard_A0'
  'Standard_A1'
  'Standard_A10'
  'Standard_A11'
  'Standard_A1_v2'
  'Standard_A2'
  'Standard_A2_v2'
  'Standard_A2m_v2'
  'Standard_A3'
  'Standard_A4'
  'Standard_A4_v2'
  'Standard_A4m_v2'
  'Standard_A5'
  'Standard_A6'
  'Standard_A7'
  'Standard_A8'
  'Standard_A8_v2'
  'Standard_A8m_v2'
  'Standard_A9'
  'Standard_B1ms'
  'Standard_B1s'
  'Standard_B2ms'
  'Standard_B2s'
  'Standard_B4ms'
  'Standard_B8ms'
  'Standard_D1'
  'Standard_D11'
  'Standard_D11_v2'
  'Standard_D11_v2_Promo'
  'Standard_D12'
  'Standard_D12_v2'
  'Standard_D12_v2_Promo'
  'Standard_D13'
  'Standard_D13_v2'
  'Standard_D13_v2_Promo'
  'Standard_D14'
  'Standard_D14_v2'
  'Standard_D14_v2_Promo'
  'Standard_D15_v2'
  'Standard_D16_v3'
  'Standard_D16s_v3'
  'Standard_D1_v2'
  'Standard_D2'
  'Standard_D2_v2'
  'Standard_D2_v2_Promo'
  'Standard_D2_v3'
  'Standard_D2s_v3'
  'Standard_D3'
  'Standard_D32_v3'
  'Standard_D32s_v3'
  'Standard_D3_v2'
  'Standard_D3_v2_Promo'
  'Standard_D4'
  'Standard_D4_v2'
  'Standard_D4_v2_Promo'
  'Standard_D4_v3'
  'Standard_D4s_v3'
  'Standard_D5_v2'
  'Standard_D5_v2_Promo'
  'Standard_D64_v3'
  'Standard_D64s_v3'
  'Standard_D8_v3'
  'Standard_D8s_v3'
  'Standard_DS1'
  'Standard_DS11'
  'Standard_DS11-1_v2'
  'Standard_DS11_v2'
  'Standard_DS11_v2_Promo'
  'Standard_DS12'
  'Standard_DS12-1_v2'
  'Standard_DS12-2_v2'
  'Standard_DS12_v2'
  'Standard_DS12_v2_Promo'
  'Standard_DS13'
  'Standard_DS13-2_v2'
  'Standard_DS13-4_v2'
  'Standard_DS13_v2'
  'Standard_DS13_v2_Promo'
  'Standard_DS14'
  'Standard_DS14-4_v2'
  'Standard_DS14-8_v2'
  'Standard_DS14_v2'
  'Standard_DS14_v2_Promo'
  'Standard_DS15_v2'
  'Standard_DS1_v2'
  'Standard_DS2'
  'Standard_DS2_v2'
  'Standard_DS2_v2_Promo'
  'Standard_DS3'
  'Standard_DS3_v2'
  'Standard_DS3_v2_Promo'
  'Standard_DS4'
  'Standard_DS4_v2'
  'Standard_DS4_v2_Promo'
  'Standard_DS5_v2'
  'Standard_DS5_v2_Promo'
  'Standard_E16-4s_v3'
  'Standard_E16-8s_v3'
  'Standard_E16_v3'
  'Standard_E16s_v3'
  'Standard_E2_v3'
  'Standard_E2s_v3'
  'Standard_E32-16s_v3'
  'Standard_E32-8s_v3'
  'Standard_E32_v3'
  'Standard_E32s_v3'
  'Standard_E4-2s_v3'
  'Standard_E4_v3'
  'Standard_E4s_v3'
  'Standard_E64-16s_v3'
  'Standard_E64-32s_v3'
  'Standard_E64_v3'
  'Standard_E64i_v3'
  'Standard_E64is_v3'
  'Standard_E64s_v3'
  'Standard_E8-2s_v3'
  'Standard_E8-4s_v3'
  'Standard_E8_v3'
  'Standard_E8s_v3'
  'Standard_F1'
  'Standard_F16'
  'Standard_F16s'
  'Standard_F16s_v2'
  'Standard_F1s'
  'Standard_F2'
  'Standard_F2s'
  'Standard_F2s_v2'
  'Standard_F32s_v2'
  'Standard_F4'
  'Standard_F4s'
  'Standard_F4s_v2'
  'Standard_F64s_v2'
  'Standard_F72s_v2'
  'Standard_F8'
  'Standard_F8s'
  'Standard_F8s_v2'
  'Standard_G1'
  'Standard_G2'
  'Standard_G3'
  'Standard_G4'
  'Standard_G5'
  'Standard_GS1'
  'Standard_GS2'
  'Standard_GS3'
  'Standard_GS4'
  'Standard_GS4-4'
  'Standard_GS4-8'
  'Standard_GS5'
  'Standard_GS5-16'
  'Standard_GS5-8'
  'Standard_H16'
  'Standard_H16m'
  'Standard_H16mr'
  'Standard_H16r'
  'Standard_H8'
  'Standard_H8m'
  'Standard_L16s'
  'Standard_L16s_v2'
  'Standard_L32s'
  'Standard_L4s'
  'Standard_L8s'
  'Standard_L8s_v2'
  'Standard_M128'
  'Standard_M128-32ms'
  'Standard_M128-64ms'
  'Standard_M128m'
  'Standard_M128ms'
  'Standard_M128s'
  'Standard_M16-4ms'
  'Standard_M16-8ms'
  'Standard_M16ms'
  'Standard_M32-16ms'
  'Standard_M32-8ms'
  'Standard_M32ls'
  'Standard_M32ms'
  'Standard_M32ts'
  'Standard_M64'
  'Standard_M64-16ms'
  'Standard_M64-32ms'
  'Standard_M64ls'
  'Standard_M64m'
  'Standard_M64ms'
  'Standard_M64s'
  'Standard_M8-2ms'
  'Standard_M8-4ms'
  'Standard_M8ms'
  'Standard_NC12'
  'Standard_NC12s_v2'
  'Standard_NC12s_v3'
  'Standard_NC24'
  'Standard_NC24r'
  'Standard_NC24rs_v2'
  'Standard_NC24rs_v3'
  'Standard_NC24s_v2'
  'Standard_NC24s_v3'
  'Standard_NC6'
  'Standard_NC6s_v2'
  'Standard_NC6s_v3'
  'Standard_ND12s'
  'Standard_ND24rs'
  'Standard_ND24s'
  'Standard_ND6s'
  'Standard_NV12'
  'Standard_NV24'
  'Standard_NV6'
])
param aksNodeVMSize string = 'Standard_D4ds_v5'

@description('The version of Kubernetes.')
param aksVersion string
param aksSubnetRef string
param suffix string

@description('Enable RBAC on the AKS cluster.')
param aksEnableRBAC bool = true

@description('list of AAD objectID GUIDs')
param aadAdminGroupObjectIdList array

@description('Log Analytics workspace resource id')
param workspaceRef string
//param appGwySubnetPrefix string
param applicationGatewayId string

var aksClusterName_var = 'aks-${suffix}'
//var appGwyName = 'appgwy-${suffix}'

resource aksClusterName 'Microsoft.ContainerService/managedClusters@2020-03-01' = {
  name: aksClusterName_var
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: aksVersion
    enableRBAC: aksEnableRBAC
    dnsPrefix: aksDnsPrefix
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceRef
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGatewayId
          applicationGatewayWatchNamespace: 'dev,staging,stage,prod,default'
        }
      }
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    aadProfile: {
      managed: true
      adminGroupObjectIDs: aadAdminGroupObjectIdList
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        osDiskSizeGB: aksNodeOsDiskSizeGB
        count: aksNodeCount
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        maxPods: maxPods
        vmSize: aksNodeVMSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetRef
        enableAutoScaling: enableAutoScaling
        mode: 'System'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
      {
        name: 'userpool1'
        osDiskSizeGB: aksNodeOsDiskSizeGB
        count: aksNodeCount
        minCount: aksMinNodeCount
        maxCount: aksMaxNodeCount
        maxPods: maxPods
        vmSize: aksNodeVMSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetRef
        enableAutoScaling: enableAutoScaling
        mode: 'User'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      serviceCidr: '10.100.0.0/16'
      dnsServiceIP: '10.100.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'userDefinedRouting'
      loadBalancerSku: 'standard'
    }
  }
}

output aksClusterName string = aksClusterName_var
output aksControlPlanePrivateFQDN string = aksClusterName.properties.privateFQDN
output aksNodeResourceGroupName string = aksClusterName.properties.nodeResourceGroup
