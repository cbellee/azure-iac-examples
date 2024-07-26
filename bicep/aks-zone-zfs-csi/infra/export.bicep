param apiVersion string

@description('The name of the Managed Cluster resource.')
param resourceName string

@description('The location of AKS resource.')
param location string
param isLocationEdgeZone bool = false

@description('Extended location of the cluster.')
param edgeZone object = {}
param useServicePrincipal bool = false

@metadata({ descirption: 'The managed cluster SKU tier.' })
param clusterSku object = {
  name: 'Base'
  tier: 'Standard'
}

@description('Specifies the tags of the AKS cluster.')
param clusterTags object = {}
param tagsForAllResources object = {}

@description('The identity of the managed cluster, if configured.')
param clusterIdentity object = {
  type: 'SystemAssigned'
}

@description('Flag to turn on or off of Microsoft Entra ID Profile.')
param enableAadProfile bool = false

@metadata({ descirption: 'The Microsoft Entra ID configuration.' })
param aadProfile object = {}

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string

@description('The version of Kubernetes.')
param kubernetesVersion string = '1.7.7'

@description('Boolean flag to turn on and off of RBAC.')
param enableRBAC bool = true

@description('Boolean flag to turn on and off of virtual machine scale sets')
param windowsProfile bool = false

@description('The name of the resource group containing agent pool nodes.')
param nodeResourceGroup string

@description('Auto upgrade channel for a managed cluster.')
@allowed([
  'none'
  'patch'
  'rapid'
  'stable'
  'node-image'
])
param upgradeChannel string = 'none'

@description('Client ID (used by cloudprovider).')
@secure()
param servicePrincipalClientId string = ''

@description('The Service Principal Client Secret.')
@secure()
param servicePrincipalClientSecret string = ''

@description('An array of Microsoft Entra group object ids to give administrative access.')
param adminGroupObjectIDs array = ''

@description('The objectId of service principal.')
param principalId string = ''

@allowed([
  'AKSLongTermSupport'
  'KubernetesOfficial'
])
param supportPlan string = 'KubernetesOfficial'

@description('Enable or disable Azure RBAC.')
param azureRbac bool = false

@description('Enable or disable local accounts.')
param disableLocalAccounts bool = false

@description('Enable private network access to the Kubernetes cluster.')
param enablePrivateCluster bool = false
param isPrivateClusterSupported bool = false
param enableAuthorizedIpRange bool = false

@description('Boolean flag to turn on and off http application routing.')
param authorizedIPRanges array = []
param isPublicNetworkAccessEnabled bool = false

@description('Allow or deny public network access for AKS.')
@allowed([
  'Disabled'
  'Enabled'
  'SecuredByPerimeter'
])
param publicNetworkAccess string = 'Enabled'

@description('Flag to turn on or off of diskEncryptionSetID. Set diskEncryptionSetID to null when false.')
param enableDiskEncryptionSetID bool = false

@description('The ID of the disk encryption set used to encrypt the OS disks of the nodes.')
param diskEncryptionSetID string = ''

@secure()
param aadSessionKey string = ''
param isAzurePolicySupported bool = false

@description('Boolean flag to turn on and off Azure Policy addon.')
param enableAzurePolicy bool = false
param isSecretStoreCSIDDriverSupported bool = false

@description('Boolean flag to turn on and off secret store CSI driver.')
param enableSecretStoreCSIDriver bool = false

@description('Boolean flag to turn on and off omsagent addon.')
param enableOmsAgent bool = true

@description('Specify the region for your OMS workspace.')
param workspaceRegion string = 'East US'

@description('Specify the name of the OMS workspace.')
param workspaceName string = ''

@description('Specify the resource id of the OMS workspace.')
param omsWorkspaceId string = ''

@description('Select the SKU for your workspace.')
@allowed([
  'free'
  'standalone'
  'pernode'
])
param omsSku string = 'standalone'

@description('Name of virtual network subnet used for the ACI Connector.')
param aciVnetSubnetName string = ''

@description('Enables the Linux ACI Connector.')
param aciConnectorLinuxEnabled bool = false

@description('Specify the name of the Azure Container Registry.')
param acrName string = ''

@description('The name of the resource group the container registry is associated with.')
param acrResourceGroup string = ''

@description('The unique id used in the role assignment of the kubernetes service to the container registry service. It is recommended to use the default value.')
param guidValue string = newGuid()

@description('Flag to turn on or off of vnetSubnetID.')
param enableVnetSubnetID bool = false

@description('Resource ID of virtual network subnet used for nodes and/or pods IP assignment.')
param vnetSubnetID string = ''

@description('Specifies the sku of the load balancer used by the virtual machine scale sets used by node pools.')
@allowed([
  'Basic'
  'Standard'
])
param loadBalancerSku string = 'Standard'

@description('Network policy used for building the Kubernetes network.')
param networkPolicy string = ''

@description('Network plugin used for building the Kubernetes network.')
@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string = 'azure'

@description('Network plugin mode used for building the Kubernetes network.')
param networkPluginMode string = ''

@description('Network dataplane used in the Kubernetes cluster.')
param networkDataplane string = ''

@description('A CIDR notation IP range from which to assign service cluster IPs.')
param serviceCidr string = ''

@description('Containers DNS server IP address.')
param dnsServiceIP string = ''

@description('Possible values are any decimal value greater than zero or -1 which indicates the willingness to pay any on-demand price.')
param spotMaxPrice string = ''

@description('Boolean flag to turn on and off of virtual machine scale sets')
param vmssNodePool bool = false

@description('Boolean flag to turn on or off of Availability Zone')
param isAvailabilityZoneEnabled bool = false

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of agent nodes for the cluster. Production workloads have a recommended minimum of 3.')
@minValue(1)
@maxValue(50)
param agentCount int = 3

@description('Specifies the ScaleSetEvictionPolicy to be used to specify eviction policy for spot virtual machine scale set. Default to Delete. Allowed values are Delete or Deallocate.')
@allowed([
  'Delete'
  'Deallocate'
])
param scaleSetEvictionPolicy string = 'Delete'

@description('Specifies the virtual machine scale set priority in the user node pool: Spot or Regular.')
@allowed([
  'Spot'
  'Regular'
])
param scaleSetPriority string = 'Regular'

@description('Specifies the tags of the agent pool.')
param agentTags object = {}

@description('Some scenarios may require nodes in a node pool to receive their own dedicated public IP addresses.')
param enableNodePublicIP bool = false

@description('Specifies the taints added to new nodes during node pool create and scale. For example, key=value:NoSchedule. - string.')
param agentNodeTaints array = []

@description('Specifies the Agent pool node labels to be persisted across all nodes in the system node pool.')
param agentNodeLables object = {}

@description('Specifies the availability zones for the agent nodes in the agent node pool. Requires the use of VirtualMachineScaleSets as node pool type.')
param agentAvailabilityZones array = []

@description('A cluster must have at least one \'System\' Agent Pool at all times.')
@allowed([
  'System'
  'User'
])
param agentMode string = 'System'

@description('Specifies the maximum number of pods that can run on a node in the agent node pool. The maximum number of pods per node in an AKS cluster is 250. The default maximum number of pods per node varies between kubenet and Azure CNI networking, and the method of cluster deployment.')
param agentMaxPods int = 30

@description('The type of operating system for agent pool.')
@allowed([
  'Linux'
  'Windows'
])
param agentOSType string = 'Linux'

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2_v3'

@description('Specifies the maximum number of nodes for auto-scaling for the system node pool.')
param agentMaxCount int = 5

@description('Specifies the minimum number of nodes for auto-scaling for the system node pool.')
param agentMinCount int = 3

@description('Specifies whether to enable auto-scaling for the system node pool.')
param enableAutoScaling bool = true

@allowed([
  'Disabled'
  'Istio'
])
param serviceMeshMode string = 'Disabled'
param istioInternalIngressGateway bool = false
param istioExternalIngressGateway bool = false

@description('Auto upgrade channel for node OS security.')
@allowed([
  'None'
  'Unmanaged'
  'SecurityPatch'
  'NodeImage'
])
param nodeOSUpgradeChannel string = 'NodeImage'

var isScaleSetPrioritySpot = (scaleSetPriority == 'Spot')
var defaultAadProfile = {
  managed: true
  adminGroupObjectIDs: adminGroupObjectIDs
  enableAzureRBAC: azureRbac
}
var defaultApiServerAccessProfile = {
  authorizedIPRanges: (enableAuthorizedIpRange ? authorizedIPRanges : null)
  enablePrivateCluster: enablePrivateCluster
}
var defaultAzurePolicy = {
  enabled: enableAzurePolicy
}
var defaultSecrectStoreProvider = {
  enabled: enableSecretStoreCSIDriver
  config: (enableSecretStoreCSIDriver ? secrectStoreConfig : null)
}
var secrectStoreConfig = {
  enableSecretRotation: 'false'
  rotationPollInterval: '2m'
}
var servicePrincipalProfile = {
  ClientId: servicePrincipalClientId
  Secret: servicePrincipalClientSecret
}

module aks_monitoring_msi_dcr_1620c8a3_250b_317f_ea9b_f47f5257acb2 './nested_aks_monitoring_msi_dcr_1620c8a3_250b_317f_ea9b_f47f5257acb2.bicep' = {
  name: 'aks-monitoring-msi-dcr-1620c8a3-250b-317f-ea9b-f47f5257acb2'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    workspaceRegion: workspaceRegion
    clusterTags: clusterTags
    omsWorkspaceId: omsWorkspaceId
  }
  dependsOn: []
}

module aks_monitoring_msi_dcra_b1eab1a8_64e5_29c5_4215_ece83cde29af './nested_aks_monitoring_msi_dcra_b1eab1a8_64e5_29c5_4215_ece83cde29af.bicep' = {
  name: 'aks-monitoring-msi-dcra-b1eab1a8-64e5-29c5-4215-ece83cde29af'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    resourceId_b2375b5f_8dab_4436_b87c_32bc7fdce5d0_aks_zone_zfs_test_rg_Microsoft_Insights_dataCollectionRules_MSCI_australiaeast_aks_zone_zfs_test: resourceId(
      'b2375b5f-8dab-4436-b87c-32bc7fdce5d0',
      'aks-zone-zfs-test-rg',
      'Microsoft.Insights/dataCollectionRules',
      'MSCI-australiaeast-aks-zone-zfs-test'
    )
  }
  dependsOn: [
    resource
    aks_monitoring_msi_dcr_1620c8a3_250b_317f_ea9b_f47f5257acb2
  ]
}

module InsightsActionGroupDepl_e8247e4b_e818_cc92_ad4c_ca4ae9f7eaae './nested_InsightsActionGroupDepl_e8247e4b_e818_cc92_ad4c_ca4ae9f7eaae.bicep' = {
  name: 'InsightsActionGroupDepl-e8247e4b-e818-cc92-ad4c-ca4ae9f7eaae'
  params: {
    tagsForAllResources: tagsForAllResources
  }
}

module InsightsMetricAlertsDepl_0e68dda3_26f4_675d_7902_cae4ed2579b7 './nested_InsightsMetricAlertsDepl_0e68dda3_26f4_675d_7902_cae4ed2579b7.bicep' = {
  name: 'InsightsMetricAlertsDepl-0e68dda3-26f4-675d-7902-cae4ed2579b7'
  params: {
    resourceId_Microsoft_Insights_ActionGroups_RecommendedAlertRules_AG_1: resourceId(
      'Microsoft.Insights/ActionGroups',
      'RecommendedAlertRules-AG-1'
    )
    tagsForAllResources: tagsForAllResources
  }
  dependsOn: [
    '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.ContainerService/managedClusters/aks-zone-zfs-test'
    InsightsActionGroupDepl_e8247e4b_e818_cc92_ad4c_ca4ae9f7eaae
  ]
}

resource aks_zone_zfs_test_aksManagedAutoUpgradeSchedule 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2023-10-01' = {
  name: 'aks-zone-zfs-test/aksManagedAutoUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        daily: null
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Sunday'
        }
        absoluteMonthly: null
        relativeMonthly: null
      }
      durationHours: 4
      utcOffset: '+00:00'
      startDate: '2024-07-17'
      startTime: '00:00'
    }
  }
  dependsOn: [
    resource
  ]
}

resource aks_zone_zfs_test_aksManagedNodeOSUpgradeSchedule 'Microsoft.ContainerService/managedClusters/maintenanceConfigurations@2023-10-01' = {
  name: 'aks-zone-zfs-test/aksManagedNodeOSUpgradeSchedule'
  properties: {
    maintenanceWindow: {
      schedule: {
        weekly: {
          intervalWeeks: 1
          dayOfWeek: 'Sunday'
        }
      }
      durationHours: 4
      utcOffset: '+00:00'
      startDate: '2024-07-17'
      startTime: '00:00'
    }
  }
  dependsOn: [
    resource
  ]
}

resource resource 'Microsoft.ContainerService/managedClusters@[parameters(\'apiVersion\')]' = {
  name: resourceName
  location: location
  tags: clusterTags
  sku: clusterSku
  identity: clusterIdentity
  properties: {
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    nodeResourceGroup: nodeResourceGroup
    disableLocalAccounts: disableLocalAccounts
    aadProfile: (enableAadProfile ? defaultAadProfile : null)
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
    apiServerAccessProfile: (isPrivateClusterSupported ? defaultApiServerAccessProfile : null)
    addonProfiles: {
      azurepolicy: (isAzurePolicySupported ? defaultAzurePolicy : null)
      azureKeyvaultSecretsProvider: (isSecretStoreCSIDDriverSupported ? defaultSecrectStoreProvider : null)
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
  }
  dependsOn: []
}

module CreatePromDCE_20240716134717_44 './nested_CreatePromDCE_20240716134717_44.bicep' = {
  name: 'CreatePromDCE-20240716134717-44'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    tagsForAllResources: tagsForAllResources
  }
  dependsOn: [
    resource
  ]
}

module CreatePromDCR_20240716134717_91 './nested_CreatePromDCR_20240716134717_91.bicep' = {
  name: 'CreatePromDCR-20240716134717-91'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    tagsForAllResources: tagsForAllResources
  }
  dependsOn: [
    CreatePromDCE_20240716134717_44
    CreateAzureMonitorWorkspace_20240716134717_28
  ]
}

module CreatePromDCRA_20240716134717_19 './nested_CreatePromDCRA_20240716134717_19.bicep' = {
  name: 'CreatePromDCRA-20240716134717-19'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {}
  dependsOn: [
    CreatePromDCR_20240716134717_91
  ]
}

module CreatePromRecordingRules_20240716134717_74 './nested_CreatePromRecordingRules_20240716134717_74.bicep' = {
  name: 'CreatePromRecordingRules-20240716134717-74'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    tagsForAllResources: tagsForAllResources
  }
  dependsOn: [
    resource
    CreateAzureMonitorWorkspace_20240716134717_28
  ]
}

module CreateAzureMonitorWorkspace_20240716134717_28 './nested_CreateAzureMonitorWorkspace_20240716134717_28.bicep' = {
  name: 'CreateAzureMonitorWorkspace-20240716134717-28'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    tagsForAllResources: tagsForAllResources
  }
  dependsOn: [
    CreatePromDCE_20240716134717_44
  ]
}

module CreateGrafanaWorkspace_20240716134717_7 './nested_CreateGrafanaWorkspace_20240716134717_7.bicep' = {
  name: 'CreateGrafanaWorkspace-20240716134717-7'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {}
  dependsOn: [
    resource
  ]
}

module AddAdministratorRoleForGrafana_20240716134717_71 './nested_AddAdministratorRoleForGrafana_20240716134717_71.bicep' = {
  name: 'AddAdministratorRoleForGrafana-20240716134717-71'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {}
  dependsOn: [
    CreateGrafanaWorkspace_20240716134717_7
  ]
}

module AddMRRToGrafMSIForGraf_20240716134717_99 './nested_AddMRRToGrafMSIForGraf_20240716134717_99.bicep' = {
  name: 'AddMRRToGrafMSIForGraf-20240716134717-99'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value: CreateGrafanaWorkspace_20240716134717_7.properties
  }
}

module AddMonitorDataReaderRoleAssignmentToGraphanaMS_20240716134717_42 './nested_AddMonitorDataReaderRoleAssignmentToGraphanaMS_20240716134717_42.bicep' = {
  name: 'AddMonitorDataReaderRoleAssignmentToGraphanaMS-20240716134717-42'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value: CreateGrafanaWorkspace_20240716134717_7.properties
  }
  dependsOn: [
    CreateAzureMonitorWorkspace_20240716134717_28
  ]
}

module AddAMWIntegrationToGrafana_20240716134717_87 './nested_AddAMWIntegrationToGrafana_20240716134717_87.bicep' = {
  name: 'AddAMWIntegrationToGrafana-20240716134717-87'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {}
  dependsOn: [
    resource
    AddMonitorDataReaderRoleAssignmentToGraphanaMS_20240716134717_42
  ]
}

module ClusterOnboardingPut_e3a076cb_18e7_2b37_6cae_39e8a1502e16 './nested_ClusterOnboardingPut_e3a076cb_18e7_2b37_6cae_39e8a1502e16.bicep' = {
  name: 'ClusterOnboardingPut-e3a076cb-18e7-2b37-6cae-39e8a1502e16'
  scope: resourceGroup('b2375b5f-8dab-4436-b87c-32bc7fdce5d0', 'aks-zone-zfs-test-rg')
  params: {
    variables_defaultAadProfile: defaultAadProfile
    variables_defaultApiServerAccessProfile: defaultApiServerAccessProfile
    location: location
    clusterSku: clusterSku
    kubernetesVersion: kubernetesVersion
    enableRBAC: enableRBAC
    dnsPrefix: dnsPrefix
    nodeResourceGroup: nodeResourceGroup
    disableLocalAccounts: disableLocalAccounts
    enableAadProfile: enableAadProfile
    upgradeChannel: upgradeChannel
    nodeOSUpgradeChannel: nodeOSUpgradeChannel
    osDiskSizeGB: osDiskSizeGB
    isPrivateClusterSupported: isPrivateClusterSupported
    enableOmsAgent: enableOmsAgent
    omsWorkspaceId: omsWorkspaceId
    enableDiskEncryptionSetID: enableDiskEncryptionSetID
    diskEncryptionSetID: diskEncryptionSetID
    loadBalancerSku: loadBalancerSku
    networkPlugin: networkPlugin
    networkPluginMode: networkPluginMode
    networkDataplane: networkDataplane
    networkPolicy: networkPolicy
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP
    supportPlan: supportPlan
    clusterIdentity: clusterIdentity
    isLocationEdgeZone: isLocationEdgeZone
    edgeZone: edgeZone
    clusterTags: clusterTags
  }
  dependsOn: [
    aks_monitoring_msi_dcra_b1eab1a8_64e5_29c5_4215_ece83cde29af
    CreatePromDCRA_20240716134717_19
    CreatePromRecordingRules_20240716134717_74
  ]
}

output controlPlaneFQDN string = resource.properties.fqdn
