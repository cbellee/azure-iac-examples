@description('Specifies the location of AKS cluster.')
param location string = resourceGroup().location

@description('Specifies the name of the AKS cluster.')
param aksClusterName string = 'aks-${uniqueString(resourceGroup().id)}'

@description('Specifies the DNS prefix specified when creating the managed cluster.')
param aksClusterDnsPrefix string = aksClusterName

@description('Specifies the tags of the AKS cluster.')
param aksClusterTags object = {
  resourceType: 'AKS Cluster'
  createdBy: 'ARM Template'
}

@allowed([
  'azure'
  'kubenet'
])
@description('Specifies the network plugin used for building Kubernetes network. - azure or kubenet.')
param aksClusterNetworkPlugin string = 'azure'

@allowed([
  'azure'
  'calico'
])
@description('Specifies the network policy used for building Kubernetes network. - calico or azure')
param aksClusterNetworkPolicy string = 'azure'

@description('Specifies the CIDR notation IP range from which to assign pod IPs when kubenet is used.')
param aksClusterPodCidr string = '10.244.0.0/16'

@description('A CIDR notation IP range from which to assign service cluster IPs. It must not overlap with any Subnet IP ranges.')
param aksClusterServiceCidr string = '10.4.0.0/16'

@description('Specifies the IP address assigned to the Kubernetes DNS service. It must be within the Kubernetes service address range specified in serviceCidr.')
param aksClusterDnsServiceIP string = '10.4.0.10'

@description('Specifies the CIDR notation IP range assigned to the Docker bridge network. It must not overlap with any Subnet IP ranges or the Kubernetes service address range.')
param aksClusterDockerBridgeCidr string = '172.17.0.1/16'

@allowed([
  'basic'
  'standard'
])
@description('Specifies the sku of the load balancer used by the virtual machine scale sets used by nodepools.')
param aksClusterLoadBalancerSku string = 'standard'

@allowed([
  'loadBalancer'
  'userDefinedRouting'
])
@description('Specifies outbound (egress) routing method. - loadBalancer or userDefinedRouting.')
param aksClusterOutboundType string = 'loadBalancer'

@allowed([
  'Paid'
  'Free'
])
@description('Specifies the tier of a managed cluster SKU: Paid or Free')
param aksClusterSkuTier string = 'Paid'

@description('Specifies the version of Kubernetes specified when creating the managed cluster.')
param aksClusterKubernetesVersion string = '1.20.2'

@description('Specifies the administrator username of Linux virtual machines.')
param aksClusterAdminUsername string = 'azureuser'

@description('Specifies the SSH RSA public key string for the Linux nodes.')
param aksClusterSshPublicKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809'

@description('Specifies the tenant id of the Azure Active Directory used by the AKS cluster for authentication.')
param aadProfileTenantId string = subscription().tenantId

@description('Specifies the AAD group object IDs that will have admin role of the cluster.')
param aadProfileAdminGroupObjectIDs array = []

@description('Specifies whether to create the cluster as a private cluster or not.')
param aksClusterEnablePrivateCluster bool = true

@description('Specifies whether to enable managed AAD integration.')
param aadProfileManaged bool = true

@description('Specifies whether to  to enable Azure RBAC for Kubernetes authorization.')
param aadProfileEnableAzureRBAC bool = true

@description('Specifies the unique name of of the system node pool profile in the context of the subscription and resource group.')
param systemNodePoolName string = 'nodepool1'

@description('Specifies the vm size of nodes in the system node pool.')
param systemNodePoolVmSize string = 'Standard_F8s_v2'

@description('Specifies the OS Disk Size in GB to be used to specify the disk size for every machine in the system agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified..')
param systemNodePoolOsDiskSizeGB int = 100

@description('Specifies the number of agents (VMs) to host docker containers in the system node pool. Allowed values must be in the range of 1 to 100 (inclusive). The default value is 1.')
param systemNodePoolAgentCount int = 1

@allowed([
  'Linux'
  'Windows'
])
@description('Specifies the OS type for the vms in the system node pool. Choose from Linux and Windows. Default to Linux.')
param systemNodePoolOsType string = 'Linux'

@description('Specifies the maximum number of pods that can run on a node in the system node pool. The maximum number of pods per node in an AKS cluster is 250. The default maximum number of pods per node varies between kubenet and Azure CNI networking, and the method of cluster deployment.')
param systemNodePoolMaxPods int = 30

@description('Specifies the maximum number of nodes for auto-scaling for the system node pool.')
param systemNodePoolMaxCount int = 3

@description('Specifies the minimum number of nodes for auto-scaling for the system node pool.')
param systemNodePoolMinCount int = 1

@description('Specifies whether to enable auto-scaling for the system node pool.')
param systemNodePoolEnableAutoScaling bool = true

@allowed([
  'Spot'
  'Regular'
])
@description('Specifies the virtual machine scale set priority in the system node pool: Spot or Regular.')
param systemNodePoolScaleSetPriority string = 'Regular'

@allowed([
  'Delete'
  'Deallocate'
])
@description('Specifies the ScaleSetEvictionPolicy to be used to specify eviction policy for spot virtual machine scale set. Default to Delete. Allowed values are Delete or Deallocate.')
param systemNodePoolScaleSetEvictionPolicy string = 'Delete'

@description('Specifies the Agent pool node labels to be persisted across all nodes in the system node pool.')
param systemNodePoolNodeLabels object = {}

@description('Specifies the taints added to new nodes during node pool create and scale. For example, key=value:NoSchedule. - string')
param systemNodePoolNodeTaints array = []

@allowed([
  'VirtualMachineScaleSets'
  'AvailabilitySet'
])
@description('Specifies the type for the system node pool: VirtualMachineScaleSets or AvailabilitySet')
param systemNodePoolType string = 'VirtualMachineScaleSets'

@description('Specifies the availability zones for the agent nodes in the system node pool. Requirese the use of VirtualMachineScaleSets as node pool type.')
param systemNodePoolAvailabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Specifies the unique name of of the user node pool profile in the context of the subscription and resource group.')
param userNodePoolName string = 'nodepool2'

@description('Specifies the vm size of nodes in the user node pool.')
param userNodePoolVmSize string = 'Standard_F8s_v2'

@description('Specifies the OS Disk Size in GB to be used to specify the disk size for every machine in the system agent pool. If you specify 0, it will apply the default osDisk size according to the vmSize specified..')
param userNodePoolOsDiskSizeGB int = 100

@description('Specifies the number of agents (VMs) to host docker containers in the user node pool. Allowed values must be in the range of 1 to 100 (inclusive). The default value is 1.')
param userNodePoolAgentCount int = 1

@allowed([
  'Linux'
  'Windows'
])
@description('Specifies the OS type for the vms in the user node pool. Choose from Linux and Windows. Default to Linux.')
param userNodePoolOsType string = 'Linux'

@description('Specifies the maximum number of pods that can run on a node in the user node pool. The maximum number of pods per node in an AKS cluster is 250. The default maximum number of pods per node varies between kubenet and Azure CNI networking, and the method of cluster deployment.')
param userNodePoolMaxPods int = 30

@description('Specifies the maximum number of nodes for auto-scaling for the user node pool.')
param userNodePoolMaxCount int = 5

@description('Specifies the minimum number of nodes for auto-scaling for the user node pool.')
param userNodePoolMinCount int = 1

@description('Specifies whether to enable auto-scaling for the user node pool.')
param userNodePoolEnableAutoScaling bool = true

@allowed([
  'Spot'
  'Regular'
])
@description('Specifies the virtual machine scale set priority in the user node pool: Spot or Regular.')
param userNodePoolScaleSetPriority string = 'Regular'

@allowed([
  'Delete'
  'Deallocate'
])
@description('Specifies the ScaleSetEvictionPolicy to be used to specify eviction policy for spot virtual machine scale set. Default to Delete. Allowed values are Delete or Deallocate.')
param userNodePoolScaleSetEvictionPolicy string = 'Delete'

@description('Specifies the Agent pool node labels to be persisted across all nodes in the user node pool.')
param userNodePoolNodeLabels object = {}

@description('Specifies the taints added to new nodes during node pool create and scale. For example, key=value:NoSchedule. - string')
param userNodePoolNodeTaints array = []

@allowed([
  'VirtualMachineScaleSets'
  'AvailabilitySet'
])
@description('Specifies the type for the user node pool: VirtualMachineScaleSets or AvailabilitySet')
param userNodePoolType string = 'VirtualMachineScaleSets'

@description('Specifies the availability zones for the agent nodes in the user node pool. Requirese the use of VirtualMachineScaleSets as node pool type.')
param userNodePoolAvailabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Specifies whether the httpApplicationRouting add-on is enabled or not.')
param httpApplicationRoutingEnabled bool = false

@description('Specifies whether the aciConnectorLinux add-on is enabled or not.')
param aciConnectorLinuxEnabled bool = false

@description('Specifies whether the azurepolicy add-on is enabled or not.')
param azurePolicyEnabled bool = true

@description('Specifies whether the kubeDashboard add-on is enabled or not.')
param kubeDashboardEnabled bool = false

@description('Specifies whether the pod identity addon is enabled..')
param podIdentityProfileEnabled bool = false

@description('Specifies the scan interval of the auto-scaler of the AKS cluster.')
param autoScalerProfileScanInterval string = '10s'

@description('Specifies the scale down delay after add of the auto-scaler of the AKS cluster.')
param autoScalerProfileScaleDownDelayAfterAdd string = '10m'

@description('Specifies the scale down delay after delete of the auto-scaler of the AKS cluster.')
param autoScalerProfileScaleDownDelayAfterDelete string = '20s'

@description('Specifies scale down delay after failure of the auto-scaler of the AKS cluster.')
param autoScalerProfileScaleDownDelayAfterFailure string = '3m'

@description('Specifies the scale down unneeded time of the auto-scaler of the AKS cluster.')
param autoScalerProfileScaleDownUnneededTime string = '10m'

@description('Specifies the scale down unready time of the auto-scaler of the AKS cluster.')
param autoScalerProfileScaleDownUnreadyTime string = '20m'

@description('Specifies the utilization threshold of the auto-scaler of the AKS cluster.')
param autoScalerProfileUtilizationThreshold string = '0.5'

@description('Specifies the max graceful termination time interval in seconds for the auto-scaler of the AKS cluster.')
param autoScalerProfileMaxGracefulTerminationSec string = '600'

@description('Specifies the name of the virtual network.')
param virtualNetworkName string = '${aksClusterName}Vnet'

@description('Specifies the address prefixes of the virtual network.')
param virtualNetworkAddressPrefixes string = '10.0.0.0/8'

@description('Specifies the name of the subnet hosting the system node pool of the AKS cluster.')
param aksSubnetName string = 'AksSystemSubnet'

@description('Specifies the address prefix of the subnet hosting the system node pool of the AKS cluster.')
param aksSubnetAddressPrefix string = '10.0.0.0/16'

@description('Specifies the name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string = '${aksClusterName}Workspace'

@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
@description('Specifies the service tier of the workspace: Free, Standalone, PerNode, Per-GB.')
param logAnalyticsSku string = 'PerNode'

@description('Specifies the workspace data retention in days. -1 means Unlimited retention for the Unlimited Sku. 730 days is the maximum allowed for all other Skus.')
param logAnalyticsRetentionInDays int = 60

@description('Specifies the name of the subnet which contains the virtual machine.')
param vmSubnetName string = 'VmSubnet'

@description('Specifies the address prefix of the subnet which contains the virtual machine.')
param vmSubnetAddressPrefix string = '10.1.0.0/16'

@description('Specifies the name of the subnet which contains the the Application Gateway.')
param applicationGatewaySubnetName string = 'ApplicationGatewaySubnet'

@description('Specifies the address prefix of the subnet which contains the Application Gateway.')
param applicationGatewaySubnetAddressPrefix string = '10.2.0.0/24'

@description('Specifies the name of the virtual machine.')
param vmName string = 'TestVm'

@description('Specifies the size of the virtual machine.')
param vmSize string = 'Standard_DS3_v2'

@description('Specifies the image publisher of the disk image used to create the virtual machine.')
param imagePublisher string = 'Canonical'

@description('Specifies the offer of the platform image or marketplace image used to create the virtual machine.')
param imageOffer string = 'UbuntuServer'

@description('Specifies the Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param imageSku string = '18.04-LTS'

@allowed([
  'sshPublicKey'
  'password'
])
@description('Specifies the type of authentication when accessing the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string = 'localadmin'

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Specifies the storage account type for OS and data disk.')
param diskStorageAccountType string = 'Premium_LRS'

@minValue(0)
@maxValue(64)
@description('Specifies the number of data disks of the virtual machine.')
param numDataDisks int = 1

@description('Specifies the size in GB of the OS disk of the VM.')
param osDiskSize int = 50

@description('Specifies the size in GB of the OS disk of the virtual machine.')
param dataDiskSize int = 50

@description('Specifies the caching requirements for the data disks.')
param dataDiskCaching string = 'ReadWrite'

@description('Specifies the globally unique name for the storage account used to store the boot diagnostics logs of the virtual machine.')
param blobStorageAccountName string = 'boot${uniqueString(resourceGroup().id)}'

@description('Specifies the name of the private link to the boot diagnostics storage account.')
param blobStorageAccountPrivateEndpointName string = 'BlobStorageAccountPrivateEndpoint'

@description('Specifies the name of the private link to the Azure Container Registry.')
param acrPrivateEndpointName string = 'AcrPrivateEndpoint'

@minLength(5)
@maxLength(50)
@description('Name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Enable admin user that have push / pull permission to the registry.')
param acrAdminUserEnabled bool = false

@allowed([
  'Allow'
  'Deny'
])
@description('The default action of allow or deny when no other rules match. Allowed values: Allow or Deny')
param acrNetworkRuleSetDefaultAction string = 'Deny'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Whether or not public network access is allowed for the container registry. Allowed values: Enabled or Disabled')
param acrPublicNetworkAccess string = 'Enabled'

@allowed([
  'australiasoutheast'
  'canadaeast'
  'eastus2'
  'westus'
  'centralus'
  'westcentralus'
  'francesouth'
  'germanynorth'
  'westeurope'
  'ukwest'
  'northeurope'
  'japanwest'
  'southafricawest'
  'northcentralus'
  'eastasia'
  'eastus'
  'westus2'
  'francecentral'
  'uksouth'
  'japaneast'
  'southeastasia'
])
@description('For Azure resources that support native geo-redunancy, provide the location the redundant service will have its secondary. Should be different than the location parameter and ideally should be a paired region - https://docs.microsoft.com/azure/best-practices-availability-paired-regions. This region does not need to support availability zones.')
param acrGeoReplicationLocation string = 'eastus'

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Tier of your Azure Container Registry.')
param acrSku string = 'Premium'

@description('Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.')
param bastionSubnetAddressPrefix string = '10.2.1.0/24'

@description('Specifies the name of the Azure Bastion resource.')
param bastionHostName string = '${aksClusterName}Bastion'

@description('Specifies the name of the private link to the Key Vault.')
param keyVaultPrivateEndpointName string = 'KeyVaultPrivateEndpoint'

@description('Specifies the name of the Key Vault resource.')
param keyVaultName string = 'keyvault-${uniqueString(resourceGroup().id)}'

@allowed([
  'Allow'
  'Deny'
])
@description('The default action of allow or deny when no other rules match. Allowed values: Allow or Deny')
param keyVaultNetworkRuleSetDefaultAction string = 'Deny'

@description('Specifies the name of the Application Gateway.')
param applicationGatewayName string = 'appgw-${uniqueString(resourceGroup().id)}'

@description('Specifies the availability zones of the Application Gateway.')
param applicationGatewayZones array = [
  '1'
  '2'
  '3'
]

@description('Specifies the name of the WAF policy')
param wafPolicyName string = '${applicationGatewayName}WafPolicy'

@allowed([
  'Detection'
  'Prevention'
])
@description('Specifies the mode of the WAF policy.')
param wafPolicyMode string = 'Prevention'

@allowed([
  'Enabled'
  'Disabled'
])
@description('Specifies the state of the WAF policy.')
param wafPolicyState string = 'Enabled'

@description('Specifies the maximum file upload size in Mb for the WAF policy.')
param wafPolicyFileUploadLimitInMb int = 100

@description('Specifies the maximum request body size in Kb for the WAF policy.')
param wafPolicyMaxRequestBodySizeInKb int = 128

@description('Specifies the whether to allow WAF to check request Body.')
param wafPolicyRequestBodyCheck bool = true

@description('Specifies the rule set type.')
param wafPolicyRuleSetType string = 'OWASP'

@description('Specifies the rule set version.')
param wafPolicyRuleSetVersion string = '3.1'

var readerRoleDefinitionName = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleDefinitionName = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var acrPullRoleDefinitionName = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var aksClusterUserDefinedManagedIdentityName = '${aksClusterName}ManagedIdentity'
var aksClusterUserDefinedManagedIdentityId = aksClusterUserDefinedManagedIdentity.id
var applicationGatewayUserDefinedManagedIdentityName = '${applicationGatewayName}ManagedIdentity'
var applicationGatewayUserDefinedManagedIdentityId = applicationGatewayUserDefinedManagedIdentity.id
var aadPodIdentityUserDefinedManagedIdentityName = '${aksClusterName}AadPodManagedIdentity'
var aadPodIdentityUserDefinedManagedIdentityId = aadPodIdentityUserDefinedManagedIdentity.id
var bastionSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, bastionSubnetName)
var readerRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${readerRoleDefinitionName}'
var contributorRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${contributorRoleDefinitionName}'
var acrPullRoleId = '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/${acrPullRoleDefinitionName}'
var aksContributorRoleAssignmentName = guid('${resourceGroup().id}${aksClusterUserDefinedManagedIdentityName}ContributorRoleAssignment')
var appGwContributorRoleAssignmentName = guid('${resourceGroup().id}${applicationGatewayUserDefinedManagedIdentityName}ContributorRoleAssignment')
var acrPullRoleAssignmentName = 'Microsoft.Authorization/${guid('${resourceGroup().id}acrPullRoleAssignment')}'

var vmSubnetNsgName = '${vmSubnetName}Nsg'
var bastionSubnetNsgName = '${bastionHostName}Nsg'
var aksSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, aksSubnetName)
var vmSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, vmSubnetName)
var applicationGatewaySubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, applicationGatewaySubnetName)

var vmNicName = '${vmName}Nic'
var blobPublicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var blobPrivateDnsZoneName = 'privatelink.${blobPublicDNSZoneForwarder}'
var blobStorageAccountPrivateEndpointGroupName = 'blob'
var blobPrivateDnsZoneGroupName = '${blobStorageAccountPrivateEndpointGroupName}PrivateDnsZoneGroup'

var omsAgentForLinuxName = 'LogAnalytics'
var omsDependencyAgentForLinuxName = 'DependencyAgent'
var containerInsightsSolutionName = 'ContainerInsights(${logAnalyticsWorkspaceName})'

var bastionPublicIpAddressName = '${bastionHostName}PublicIp'
var bastionSubnetName = 'AzureBastionSubnet'

var acrPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? 'azurecr.us' : 'azurecr.io')
var acrPrivateDnsZoneName = 'privatelink.${acrPublicDNSZoneForwarder}'
var acrPrivateEndpointGroupName = 'registry'
var acrPrivateDnsZoneGroupName = '${acrPrivateEndpointGroupName}PrivateDnsZoneGroup'

var keyVaultPublicDNSZoneForwarder = ((toLower(environment().name) == 'azureusgovernment') ? '.vaultcore.usgovcloudapi.net' : '.vaultcore.azure.net')
var keyVaultPrivateDnsZoneName = 'privatelink${keyVaultPublicDNSZoneForwarder}'
var keyVaultPrivateEndpointGroupName = 'vault'
var keyVaultPrivateDnsZoneGroupName = '${keyVaultPrivateEndpointGroupName}PrivateDnsZoneGroup'

var applicationGatewayPublicIPAddressName = '${applicationGatewayName}PublicIp'
var applicationGatewayIPConfigurationName = 'applicationGatewayIPConfiguration'
var applicationGatewayFrontendIPConfigurationName = 'applicationGatewayFrontendIPConfiguration'
var applicationGatewayFrontendIPConfigurationId = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, applicationGatewayFrontendIPConfigurationName)
var applicationGatewayFrontendPortName = 'applicationGatewayFrontendPort'
var applicationGatewayFrontendPortId = resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, applicationGatewayFrontendPortName)
var applicationGatewayHttpListenerName = 'applicationGatewayHttpListener'
var applicationGatewayHttpListenerId = resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, applicationGatewayHttpListenerName)
var applicationGatewayBackendAddressPoolName = 'applicationGatewayBackendPool'
var applicationGatewayBackendAddressPoolId = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, applicationGatewayBackendAddressPoolName)
var applicationGatewayBackendHttpSettingsName = 'applicationGatewayBackendHttpSettings'
var applicationGatewayBackendHttpSettingsId = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, applicationGatewayBackendHttpSettingsName)
var applicationGatewayRequestRoutingRuleName = 'default'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: vmAdminPasswordOrKey
      }
    ]
  }
  provisionVMAgent: true
}

resource bastionPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: bastionPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionSubnetNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: bastionSubnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource bastionSubnetNsgInsights 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${bastionSubnetNsg.name}/Microsoft.Insights/default'
  location: location
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: []
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    bastionSubnetNsg
    logAnalyticsWorkspace
  ]
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIpAddress.id
          }
        }
      }
    ]
  }
  dependsOn: [
    bastionPublicIpAddress
    virtualNetwork
  ]
}

resource bastionHostInsights 'Microsoft.Network/bastionHosts/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${bastionHostName}/Microsoft.Insights/default'
  location: location
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: []
    logs: [
      {
        category: 'BastionAuditLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [
    bastionHost
    logAnalyticsWorkspace
  ]
}

resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: blobStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource vmNic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        name: '${vmName}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        managedDisk: {
          storageAccountType: diskStorageAccountType
        }
      }
      dataDisks: [
        {
          caching: dataDiskCaching
          diskSizeGB: dataDiskSize
          lun: 0
          name: '${vmName}-DataDisk'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: diskStorageAccountType
          }
        }
      ]
      /*       copy: [
        {
          name: 'dataDisks'
          count: numDataDisks
          input: {
            caching: dataDiskCaching
            diskSizeGB: dataDiskSize
            lun: copyIndex('dataDisks')
            name: '${vmName}-DataDisk${copyIndex('dataDisks')}'
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: diskStorageAccountType
            }
          }
        }
      ] */
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(blobStorageAccount.id).primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    vmNic
  ]
}

resource vmOmsAgentForLinux 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/${omsAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.12'
    settings: {
      workspaceId: reference(logAnalyticsWorkspace.id, '2020-03-01-preview').customerId
      stopOnMultipleConnections: false
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
    }
  }
  dependsOn: [
    vm
    logAnalyticsWorkspace
  ]
}

resource vmOmsDependencyAgentForLinux 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/${omsDependencyAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vm
    logAnalyticsWorkspace
    vmOmsAgentForLinux
  ]
}

resource vmSubnetNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: vmSubnetNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSshInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vmSubnetNsgInsights 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${vmSubnetNsgName}/Microsoft.Insights/default'
  location: location
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: []
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    vmSubnetNsg
    logAnalyticsWorkspace
  ]
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefixes
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
          networkSecurityGroup: {
            id: vmSubnetNsg.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: applicationGatewaySubnetName
        properties: {
          addressPrefix: applicationGatewaySubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
          networkSecurityGroup: {
            id: bastionSubnetNsg.id
          }
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn: [
    vmSubnetNsg
    bastionSubnetNsg
  ]
}

resource aksClusterUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aksClusterUserDefinedManagedIdentityName
  location: location
}

resource applicationGatewayUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: applicationGatewayUserDefinedManagedIdentityName
  location: location
}

resource aadPodIdentityUserDefinedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: aadPodIdentityUserDefinedManagedIdentityName
  location: location
}

resource aksContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: aksContributorRoleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleId
    description: 'Assign the cluster user-defined managed identity contributor role on the resource group.'
    principalId: reference(aksClusterUserDefinedManagedIdentityName).principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aksClusterUserDefinedManagedIdentity
    virtualNetwork
  ]
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: [
      {
        tenantId: reference(applicationGatewayUserDefinedManagedIdentityId).tenantId
        objectId: reference(applicationGatewayUserDefinedManagedIdentityId).principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
          ]
          keys: []
        }
      }
      {
        tenantId: reference(aadPodIdentityUserDefinedManagedIdentityId).tenantId
        objectId: reference(aadPodIdentityUserDefinedManagedIdentityId).principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
          ]
          keys: []
        }
      }
    ]
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: keyVaultNetworkRuleSetDefaultAction
      ipRules: []
      virtualNetworkRules: []
    }
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: false
  }
  dependsOn: [
    applicationGatewayUserDefinedManagedIdentity
    aadPodIdentityUserDefinedManagedIdentity
  ]
}

resource keyVaultInsights 'Microsoft.KeyVault/vaults/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${keyVaultName}/Microsoft.Insights/default'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AuditEvent'
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
  dependsOn: [
    keyVault
    logAnalyticsWorkspace
  ]
}

resource keyVaultName_Microsoft_Authorization_id_readerRoleId 'Microsoft.KeyVault/vaults/providers/roleAssignments@2020-04-01-preview' = {
  name: '${keyVaultName}/Microsoft.Authorization/${guid(concat(resourceGroup().id), readerRoleId)}'
  properties: {
    roleDefinitionId: readerRoleId
    principalId: reference(aadPodIdentityUserDefinedManagedIdentityId).principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    keyVault
    aadPodIdentityUserDefinedManagedIdentity
  ]
}

resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  tags: {
    displayName: 'Container Registry'
    'container.registry': acrName
  }
  sku: {
    name: acrSku
    tier: acrSku
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
    networkRuleSet: {
      defaultAction: acrNetworkRuleSetDefaultAction
      virtualNetworkRules: []
      ipRules: []
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 15
        status: 'enabled'
      }
    }
    publicNetworkAccess: acrPublicNetworkAccess
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: true
    networkRuleBypassOptions: 'AzureServices'
  }
  dependsOn: [
    acrPrivateDnsZone
  ]
}

resource acrPullRoleAssignment 'Microsoft.ContainerRegistry/registries/providers/roleAssignments@2020-04-01-preview' = {
  name: '${acrName}/${acrPullRoleAssignmentName}'
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: reference(aksCluster.id, '2020-12-01', 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aksCluster
    acr
  ]
}

resource acrGeoReplication 'Microsoft.ContainerRegistry/registries/replications@2019-05-01' = if (acrSku == 'Premium') {
  name: '${acr.name}/${acrGeoReplicationLocation}'
  location: acrGeoReplicationLocation
  dependsOn: [
    acr
  ]
}

resource acrInsights 'Microsoft.ContainerRegistry/registries/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${acr.name}/Microsoft.Insights/default'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        timeGrain: 'PT1M'
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
  }
  dependsOn: [
    acr
    logAnalyticsWorkspace
  ]
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${aksClusterUserDefinedManagedIdentityId}': {}
    }
  }
  tags: aksClusterTags
  properties: {
    kubernetesVersion: aksClusterKubernetesVersion
    dnsPrefix: aksClusterDnsPrefix
    sku: {
      name: 'Basic'
      tier: aksClusterSkuTier
    }
    agentPoolProfiles: [
      {
        name: toLower(systemNodePoolName)
        count: systemNodePoolAgentCount
        vmSize: systemNodePoolVmSize
        osDiskSizeGB: systemNodePoolOsDiskSizeGB
        vnetSubnetID: aksSubnetId
        maxPods: systemNodePoolMaxPods
        osType: systemNodePoolOsType
        maxCount: systemNodePoolMaxCount
        minCount: systemNodePoolMinCount
        scaleSetPriority: systemNodePoolScaleSetPriority
        scaleSetEvictionPolicy: systemNodePoolScaleSetEvictionPolicy
        enableAutoScaling: systemNodePoolEnableAutoScaling
        mode: 'System'
        type: systemNodePoolType
        availabilityZones: systemNodePoolAvailabilityZones
        nodeLabels: systemNodePoolNodeLabels
        nodeTaints: systemNodePoolNodeTaints
      }
      {
        name: toLower(userNodePoolName)
        count: userNodePoolAgentCount
        vmSize: userNodePoolVmSize
        osDiskSizeGB: userNodePoolOsDiskSizeGB
        vnetSubnetID: aksSubnetId
        maxPods: userNodePoolMaxPods
        osType: userNodePoolOsType
        maxCount: userNodePoolMaxCount
        minCount: userNodePoolMinCount
        scaleSetPriority: userNodePoolScaleSetPriority
        scaleSetEvictionPolicy: userNodePoolScaleSetEvictionPolicy
        enableAutoScaling: userNodePoolEnableAutoScaling
        mode: 'User'
        type: userNodePoolType
        availabilityZones: userNodePoolAvailabilityZones
        nodeLabels: userNodePoolNodeLabels
        nodeTaints: userNodePoolNodeTaints
      }
    ]
    linuxProfile: {
      adminUsername: aksClusterAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: aksClusterSshPublicKey
          }
        ]
      }
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: httpApplicationRoutingEnabled
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
      aciConnectorLinux: {
        enabled: aciConnectorLinuxEnabled
      }
      azurepolicy: {
        enabled: azurePolicyEnabled
        config: {
          version: 'v2'
        }
      }
      kubeDashboard: {
        enabled: kubeDashboardEnabled
      }
      ingressApplicationGateway: {
        config: {
          applicationGatewayId: applicationGateway.id
        }
        enabled: true
        identity: {
          clientId: reference(applicationGatewayUserDefinedManagedIdentityId).clientId
          objectId: reference(applicationGatewayUserDefinedManagedIdentityId).principalId
          resourceId: applicationGatewayUserDefinedManagedIdentityId
        }
      }
    }
    podIdentityProfile: {
      enabled: podIdentityProfileEnabled
    }
    enableRBAC: true
    networkProfile: {
      networkPlugin: aksClusterNetworkPlugin
      networkPolicy: aksClusterNetworkPolicy
      podCidr: aksClusterPodCidr
      serviceCidr: aksClusterServiceCidr
      dnsServiceIP: aksClusterDnsServiceIP
      dockerBridgeCidr: aksClusterDockerBridgeCidr
      outboundType: aksClusterOutboundType
      loadBalancerSku: aksClusterLoadBalancerSku
      loadBalancerProfile: json('null')
    }
    aadProfile: {
      clientAppID: json('null')
      serverAppID: json('null')
      serverAppSecret: json('null')
      managed: aadProfileManaged
      enableAzureRBAC: aadProfileEnableAzureRBAC
      adminGroupObjectIDs: aadProfileAdminGroupObjectIDs
      tenantID: aadProfileTenantId
    }
    autoScalerProfile: {
      'scan-interval': autoScalerProfileScanInterval
      'scale-down-delay-after-add': autoScalerProfileScaleDownDelayAfterAdd
      'scale-down-delay-after-delete': autoScalerProfileScaleDownDelayAfterDelete
      'scale-down-delay-after-failure': autoScalerProfileScaleDownDelayAfterFailure
      'scale-down-unneeded-time': autoScalerProfileScaleDownUnneededTime
      'scale-down-unready-time': autoScalerProfileScaleDownUnreadyTime
      'scale-down-utilization-threshold': autoScalerProfileUtilizationThreshold
      'max-graceful-termination-sec': autoScalerProfileMaxGracefulTerminationSec
    }
    apiServerAccessProfile: {
      enablePrivateCluster: aksClusterEnablePrivateCluster
    }
  }
  dependsOn: [
    virtualNetwork
    logAnalyticsWorkspace
    keyVaultPrivateDnsZone
    acrPrivateDnsZone
    applicationGateway
    aksContributorRoleAssignment
  ]
}

resource aksClusterInsights 'Microsoft.ContainerService/managedClusters/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${aksClusterName}/Microsoft.Insights/default'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
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
  dependsOn: [
    aksCluster
    logAnalyticsWorkspace
  ]
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: logAnalyticsSku
    }
    retentionInDays: logAnalyticsRetentionInDays
  }
}

resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: containerInsightsSolutionName
  location: location
  plan: {
    name: containerInsightsSolutionName
    promotionCode: ''
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
    containedResources: []
  }
}

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: keyVaultPrivateDnsZoneName
  location: 'global'
}

resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (acrSku == 'Premium') {
  name: acrPrivateDnsZoneName
  location: 'global'
}

resource blobPrivateDnsZoneName_link_to_virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateDnsZone.name}/link_to_${toLower(virtualNetwork.name)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
  dependsOn: [
    blobPrivateDnsZone
    virtualNetwork
  ]
}

resource keyVaultPrivateDnsZoneName_link_to_virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${keyVaultPrivateDnsZone.name}/link_to_${toLower(virtualNetwork.name)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
  dependsOn: [
    keyVaultPrivateDnsZone
    virtualNetwork
  ]
}

resource acrPrivateDnsZoneName_link_to_virtualNetwork 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (acrSku == 'Premium') {
  name: '${acrPrivateDnsZoneName}/link_to_${toLower(virtualNetwork.name)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
  dependsOn: [
    acrPrivateDnsZone
    virtualNetwork
  ]
}

resource blobStorageAccountPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: blobStorageAccountPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: blobStorageAccountPrivateEndpointName
        properties: {
          privateLinkServiceId: blobStorageAccount.id
          groupIds: [
            blobStorageAccountPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: vmSubnetId
    }
  }
  dependsOn: [
    virtualNetwork
    blobStorageAccount
  ]
}

resource blobStorageAccountPrivateEndpointName_blobPrivateDnsZoneGroupName 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${blobStorageAccountPrivateEndpoint.name}/${blobPrivateDnsZoneGroupName}'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: blobPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    blobStorageAccountPrivateEndpoint
    blobPrivateDnsZone
    blobStorageAccountPrivateEndpoint
  ]
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            keyVaultPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: vmSubnetId
    }
  }
  dependsOn: [
    virtualNetwork
    keyVault
  ]
}

resource keyVaultPrivateEndpointPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = {
  name: '${keyVaultPrivateEndpoint.name}/${keyVaultPrivateDnsZoneGroupName}'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    keyVault
    keyVaultPrivateDnsZone
    keyVaultPrivateEndpoint
  ]
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = if (acrSku == 'Premium') {
  name: acrPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: acrPrivateEndpointName
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            acrPrivateEndpointGroupName
          ]
        }
      }
    ]
    subnet: {
      id: vmSubnetId
    }
  }
  dependsOn: [
    virtualNetwork
    acr
    acrGeoReplication
  ]
}

resource acrPrivateEndpointPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-07-01' = if (acrSku == 'Premium') {
  name: '${acrPrivateEndpoint.name}/${acrPrivateDnsZoneGroupName}'
  location: location
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    acr
    acrPrivateDnsZone
    acrPrivateEndpoint
  ]
}

resource AllAzureAdvisorAlert 'microsoft.insights/activityLogAlerts@2017-04-01' = {
  name: 'AllAzureAdvisorAlert'
  location: 'Global'
  properties: {
    scopes: [
      resourceGroup().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Recommendation'
        }
        {
          field: 'operationName'
          equals: 'Microsoft.Advisor/recommendations/available/action'
        }
      ]
    }
    actions: {
      actionGroups: []
    }
    enabled: true
    description: 'All azure advisor alerts'
  }
}

resource applicationGatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: applicationGatewayPublicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2020-06-01' = {
  name: wafPolicyName
  location: location
  properties: {
    customRules: [
      {
        name: 'BlockMe'
        priority: 1
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'QueryString'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'blockme'
            ]
            transforms: []
          }
        ]
      }
      {
        name: 'BlockEvilBot'
        priority: 2
        ruleType: 'MatchRule'
        action: 'Block'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RequestHeaders'
                selector: 'User-Agent'
              }
            ]
            operator: 'Contains'
            negationConditon: false
            matchValues: [
              'evilbot'
            ]
            transforms: [
              'Lowercase'
            ]
          }
        ]
      }
    ]
    policySettings: {
      requestBodyCheck: wafPolicyRequestBodyCheck
      maxRequestBodySizeInKb: wafPolicyMaxRequestBodySizeInKb
      fileUploadLimitInMb: wafPolicyFileUploadLimitInMb
      mode: wafPolicyMode
      state: wafPolicyState
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: wafPolicyRuleSetType
          ruleSetVersion: wafPolicyRuleSetVersion
        }
      ]
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayUserDefinedManagedIdentity.id}': {}
    }
  }
  zones: applicationGatewayZones
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    trustedRootCertificates: []
    gatewayIPConfigurations: [
      {
        name: applicationGatewayIPConfigurationName
        properties: {
          subnet: {
            id: applicationGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: applicationGatewayFrontendIPConfigurationName
        properties: {
          publicIPAddress: {
            id: applicationGatewayPublicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: applicationGatewayFrontendPortName
        properties: {
          port: 80
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
    enableHttp2: false
    sslCertificates: []
    probes: [
      {
        name: 'defaultHttpProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
      {
        name: 'defaultHttpsProbe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
    ]
    backendAddressPools: [
      {
        name: applicationGatewayBackendAddressPoolName
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: applicationGatewayBackendHttpSettingsName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: applicationGatewayHttpListenerName
        properties: {
          firewallPolicy: {
            id: wafPolicy.id
          }
          frontendIPConfiguration: {
            id: applicationGatewayFrontendIPConfigurationId
          }
          frontendPort: {
            id: applicationGatewayFrontendPortId
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: applicationGatewayRequestRoutingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: applicationGatewayHttpListenerId
          }
          backendAddressPool: {
            id: applicationGatewayBackendAddressPoolId
          }
          backendHttpSettings: {
            id: applicationGatewayBackendHttpSettingsId
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: wafPolicyMode
      ruleSetType: wafPolicyRuleSetType
      ruleSetVersion: wafPolicyRuleSetVersion
      requestBodyCheck: wafPolicyRequestBodyCheck
      maxRequestBodySizeInKb: wafPolicyMaxRequestBodySizeInKb
      fileUploadLimitInMb: wafPolicyFileUploadLimitInMb
    }
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
  dependsOn: [
    keyVault
    applicationGatewayPublicIPAddress
    virtualNetwork
    wafPolicy
  ]
}

resource applicationGatewayInsights 'Microsoft.Network/applicationGateways/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${applicationGatewayName}/Microsoft.Insights/default'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
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
  dependsOn: [
    applicationGateway
    logAnalyticsWorkspace
  ]
}

resource appGwContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: appGwContributorRoleAssignmentName
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: reference(aksCluster.id, '2020-12-01', 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    aksCluster
    applicationGateway
  ]
}