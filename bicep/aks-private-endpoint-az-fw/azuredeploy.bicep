@description('deployment location')
param location string = resourceGroup().location

@description('resource tags')
param tags object

@description('custom vNet JSON')
param vNets array

@description('Kubernetes version')
param aksVersion string

@description('AKS node VM size')
param aksNodeVmSize string = 'Standard_D2_v2'

@description('AKS node count')
param aksNodeCount int = 1

@description('AKS max pod count per worker node')
param aksMaxPodCount int = 50

@description('AKS nodes SSH Key')
param sshPublicKey string

@description('Array of AAD principal ObjectIds')
param aadAdminGroupObjectIds array

@description('admin user name for Linux jump box VM')
param adminUsername string

param customData string

var suffix = substring(uniqueString(subscription().subscriptionId, uniqueString(resourceGroup().id)), 0, 6)
var separatedAddressprefix = split(vNets[0].subnets[0].addressPrefix, '.')
var firewallPrivateIpAddress = '${separatedAddressprefix[0]}.${separatedAddressprefix[1]}.${separatedAddressprefix[2]}.4'
var workspaceName = 'wks-${suffix}'

module module_acr 'modules/acr.bicep' = {
  name: 'module-acr'
  params: {
    tags: tags
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'Standalone'
    }
    retentionInDays: 30
  }
}

module module_udr './modules/udr.bicep' = {
  name: 'module-udr'
  params: {
    suffix: suffix
    location: location
    azureFirewallPrivateIpAddress: firewallPrivateIpAddress
  }
}

module module_vnet './modules/vnets.bicep' = [for (item, i) in vNets: {
  name: 'module-vnet-${i}'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    vNet: item
    tags: tags
  }
  dependsOn: [
    module_udr
  ]
}]

module module_peering './modules/peering.bicep' = {
  name: 'module-peering'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    module_vnet
  ]
}

module bastion_host './modules/bastion.bicep' = {
  name: 'bastion-host'
  params: {
    suffix: suffix
    tags: {
    }
    subnetId: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[2].id
  }
}

module module_vm './modules/vm.bicep' = {
  name: 'module-vm'
  params: {
    name: 'jumpbox'
    suffix: suffix
    location: location
    customData: customData
    adminUsername: adminUsername
    authenticationType: 'sshPublicKey'
    adminPasswordOrKey: sshPublicKey
    ubuntuOSVersion: '18.04-LTS'
    vmSize: 'Standard_B2s'
    subnetRef: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[1].id
  }
  dependsOn: [
    module_peering
  ]
}

module module_firewall './modules/firewall.bicep' = {
  name: 'module-firewall'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    firewallSubnetRef: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value[0].id
    sourceAddressRangePrefixes: union(reference('Microsoft.Resources/deployments/module-vnet-0').outputs.subnetRefs.value, reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value)
    vmPrivateIp: module_vm.outputs.vmPrivateIp
    workspaceRef: workspace.id
  }
}

module module_application_gateway './modules/appGateway.bicep' = {
  name: 'module-app-gateway'
  params: {
    tags: tags
    applicationGatewaySubnetId: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[2].id
    suffix: suffix 
    logAnalyticsWorkspaceId: workspace.id
  }
}

module module_aks './modules/aks.bicep' = {
  name: 'module-aks'
  params: {
    suffix: suffix
    location: location
    aksVersion: aksVersion
    aksSubnetRef: reference('Microsoft.Resources/deployments/module-vnet-1').outputs.subnetRefs.value[0].id
    applicationGatewayId: module_application_gateway.outputs.applicationGatewayId
    aksNodeVMSize: aksNodeVmSize
    aksNodeCount: aksNodeCount
    maxPods: aksMaxPodCount
    aadAdminGroupObjectIdList: aadAdminGroupObjectIds
    workspaceRef: workspace.id
  }
  dependsOn: [
    module_firewall
  ]
}

module module_privateDnsLink './modules/private-dns-link.bicep' = {
  name: 'module-privateDnsLink'
  scope: resourceGroup('MC_${resourceGroup().name}_aks-${suffix}_${resourceGroup().location}')
  params: {
    privateDnsName: module_aks.outputs.aksControlPlanePrivateFQDN
    vnetName: reference('Microsoft.Resources/deployments/module-vnet-0').outputs.vnetName.value
    vnetResourceGroupName: resourceGroup().name
  }
}

/* 
module module_sqldb './modules/sql.bicep' = if (true) {
  name: 'module-sqldb'
  params: {
    suffix: suffix
    sqlDBName: 'SampleDB'
    location: resourceGroup().location
    administratorLogin: 'dbadmin'
    administratorLoginPassword: dbAdminPassword
  }
  dependsOn: [
    module_vnet
  ]
}

module module_sqldb_private_link './modules/private_link.bicep' = {
  name: 'module-sqldb-private-link'
  params: {
    suffix: suffix
    location: location
    resourceType: 'Microsoft.Sql/servers'
    resourceName: module_sqldb.outputs.sqlServerName
    groupType: sqlGroupType
    subnet: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.subnetRefs.value[1].id
  }
  dependsOn: [
    module_vnet
  ]
}

module module_sqldb_private_dns_spoke_link './modules/private_dns.bicep' = {
  name: 'module-sqldb-private-dns-spoke-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-1')).outputs.vnetName.value
  }
  dependsOn: [
    module_sqldb_private_link
  ]
}

module module_sqldb_private_dns_hub_link './modules/private_dns.bicep' = {
  name: 'module-sqldb-private-dns-hub-link'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    virtualNetworkName: reference(resourceId('Microsoft.Resources/deployments', 'module-vnet-0')).outputs.vnetName.value
  }
  dependsOn: [
    module_sqldb_private_link
    module_sqldb_private_dns_spoke_link
  ]
}

module module_sqldb_private_link_ipconfigs './modules/private_link_ipconfigs.bicep' = {
  name: 'module-sqldb-private-link-ipconfigs'
  params: {
    privateDnsZoneName: sqlPrivateDnsZoneName
    privateLinkNicResource: module_sqldb_private_link.outputs.privateLinkNicResource
  }
  dependsOn: [
    module_sqldb_private_dns_hub_link
  ]
}
 */

output firewallPublicIpAddress string = module_firewall.outputs.firewallPublicIpAddress
output aksClusterName string = module_aks.outputs.aksClusterName
output aksClusterPrivateDnsHostName string = module_aks.outputs.aksControlPlanePrivateFQDN
output acrName string = module_acr.outputs.registryName
output acrServer string = module_acr.outputs.registryServer
output acrPassword string = module_acr.outputs.registryPassword
output acrId string = module_acr.outputs.registryResourceId
