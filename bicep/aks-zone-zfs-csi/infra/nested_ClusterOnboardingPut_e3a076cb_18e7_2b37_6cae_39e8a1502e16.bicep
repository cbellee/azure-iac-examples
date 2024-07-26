param variables_defaultAadProfile ? /* TODO: fill in correct type */
param variables_defaultApiServerAccessProfile ? /* TODO: fill in correct type */

@description('The location of AKS resource.')
param location string

@metadata({ descirption: 'The managed cluster SKU tier.' })
param clusterSku object

@description('The version of Kubernetes.')
param kubernetesVersion string

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('The name of the resource group containing agent pool nodes.')
param nodeResourceGroup string

@description('Enable or disable local accounts.')
param disableLocalAccounts bool

@description('Flag to turn on or off of Microsoft Entra ID Profile.')
param enableAadProfile bool

@description('Auto upgrade channel for a managed cluster.')
@allowed([
  'none'
  'patch'
  'rapid'
  'stable'
  'node-image'
])
param upgradeChannel string

@description('Auto upgrade channel for node OS security.')
@allowed([
  'None'
  'Unmanaged'
  'SecurityPatch'
  'NodeImage'
])
param nodeOSUpgradeChannel string

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int
param isPrivateClusterSupported bool

@description('Boolean flag to turn on and off omsagent addon.')
param enableOmsAgent bool

@description('Specify the resource id of the OMS workspace.')
param omsWorkspaceId string

@description('Flag to turn on or off of diskEncryptionSetID. Set diskEncryptionSetID to null when false.')
param enableDiskEncryptionSetID bool

@description('The ID of the disk encryption set used to encrypt the OS disks of the nodes.')
param diskEncryptionSetID string

@description('Specifies the sku of the load balancer used by the virtual machine scale sets used by node pools.')
@allowed([
  'Basic'
  'Standard'
])
param loadBalancerSku string

@description('Network plugin used for building the Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Network plugin mode used for building the Kubernetes network.')
param networkPluginMode string

@description('Network dataplane used in the Kubernetes cluster.')
param networkDataplane string

@description('Network policy used for building the Kubernetes network.')
param networkPolicy string

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string

@description('Containers DNS server IP address.')
param dnsServiceIP string

@allowed([
  'AKSLongTermSupport'
  'KubernetesOfficial'
])
param supportPlan string

@description('The identity of the managed cluster, if configured.')
param clusterIdentity object
param isLocationEdgeZone bool

@description('Extended location of the cluster.')
param edgeZone object

@description('Specifies the tags of the AKS cluster.')
param clusterTags object

resource aks_zone_zfs_test 'microsoft.containerservice/managedclusters@2023-10-01' = {
  location: location
  sku: clusterSku
  name: 'aks-zone-zfs-test'
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    nodeResourceGroup: nodeResourceGroup
    disableLocalAccounts: disableLocalAccounts
    aadProfile: (enableAadProfile ? variables_defaultAadProfile : null)
    autoUpgradeProfile: {
      upgradeChannel: upgradeChannel
      nodeOSUpgradeChannel: nodeOSUpgradeChannel
    }
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: 2
        enableAutoScaling: true
        minCount: 2
        maxCount: 5
        vmSize: 'Standard_D8ds_v5'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        maxPods: 110
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
        enableNodePublicIP: false
        tags: {}
      }
      {
        name: 'userpool'
        osDiskSizeGB: osDiskSizeGB
        count: 2
        enableAutoScaling: true
        minCount: 2
        maxCount: 100
        vmSize: 'Standard_D8ds_v5'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        maxPods: 110
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        nodeTaints: []
        enableNodePublicIP: false
        tags: {}
      }
    ]
    apiServerAccessProfile: (isPrivateClusterSupported ? variables_defaultApiServerAccessProfile : null)
    addonProfiles: {
      omsAgent: {
        enabled: enableOmsAgent
        config: {
          logAnalyticsWorkspaceResourceID: omsWorkspaceId
          useAADAuth: 'true'
        }
      }
    }
    diskEncryptionSetID: (enableDiskEncryptionSetID ? diskEncryptionSetID : null)
    networkProfile: {
      loadBalancerSku: loadBalancerSku
      networkPlugin: networkPlugin
      networkPluginMode: networkPluginMode
      networkDataplane: networkDataplane
      networkPolicy: networkPolicy
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
    }
    supportPlan: supportPlan
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricLabelsAllowlist: ''
          metricAnnotationsAllowList: ''
        }
      }
    }
  }
  identity: clusterIdentity
  extendedLocation: (isLocationEdgeZone ? edgeZone : null)
  tags: clusterTags
}
