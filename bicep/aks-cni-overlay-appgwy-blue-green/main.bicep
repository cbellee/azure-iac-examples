param location string
param adminGroupObjectID string
param tags object
param aksVersion string
param vmSku string = 'Standard_D4ds_v5'
param addressPrefix string
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param blueIngressPrivateIpAddress string
param greenIngressPrivateIpAddress string
param backendHostName string

var suffix = uniqueString(resourceGroup().id)

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    suffix: suffix
    tags: tags
    location: location
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    suffix: suffix
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
    suffix: suffix
    tags: tags
  }
}

module aks_blue './modules/aks.bicep' = {
  name: 'aksBlueDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    prefix: 'blue'
    suffix: suffix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksServiceCIDR: '10.100.0.0/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    networkPluginMode: 'overlay'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
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

module aks_green './modules/aks.bicep' = {
  name: 'aksGreenDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    location: location
    prefix: 'green'
    suffix: suffix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksServiceCIDR: '10.100.0.0/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnet.outputs.subnets[2].id
    aksUserSubnetId: vnet.outputs.subnets[3].id
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    networkPluginMode: 'overlay'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
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

resource aksBlueNetworkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'Network Contributor', 'blue', resourceGroup().id)
  properties: {
    principalId: aks_blue.outputs.systemManagedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}

resource aksGreenNetworkContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'Network Contributor', 'green', resourceGroup().id)
  properties: {
    principalId: aks_green.outputs.systemManagedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}

resource aksBluePullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'ACR Pull', 'blue', resourceGroup().id)
  properties: {
    principalId: aks_blue.outputs.kubeletIdentityObjectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

resource aksGreenPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'ACR Pull', 'green', resourceGroup().id)
  properties: {
    principalId: aks_green.outputs.kubeletIdentityObjectId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

module appGwy 'modules/appgwy.bicep' = {
  name: 'appGwy-deploy'
  params: {
    location: location
    internalHostName: backendHostName
    vnetName: vnet.outputs.vnetName
    subnetName: vnet.outputs.subnets[4].name
    blueIngressPrivateIpAddress: blueIngressPrivateIpAddress
    greenIngressPrivateIpAddress: greenIngressPrivateIpAddress
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion-deploy'
  params: {
    location: location
    subnetId: vnet.outputs.subnets[7].id
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm-deploy'
  params: {
    location: location
    adminPasswordOrKey: sshPublicKey
    adminUsername: userName
    authenticationType: 'sshPublicKey'
    subnetRef: vnet.outputs.subnets[8].id
    name: 'mgmt-vm'
    vmSize: 'Standard_D2s_v3'
  }
}

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'test.internal'
  location: 'global'
}

resource dnzZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZone
  name: 'test.internal-dns-zone-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.vnetId
    }
  }
}

resource appGatewayARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: 'gateway'
  parent: dnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: appGwy.outputs.privateIpAddress
      }
    ]
  }
}

output aksBlueClusterName string = aks_blue.outputs.aksClusterName
output aksGreenClusterName string = aks_green.outputs.aksClusterName
output aksBlueClusterFqdn string = aks_blue.outputs.aksControlPlaneFQDN
output aksGreenClusterFqdn string = aks_green.outputs.aksControlPlaneFQDN
output aksBlueClusterApiServerUri string = aks_blue.outputs.aksApiServerUri
output aksGreenClusterApiServerUri string = aks_green.outputs.aksApiServerUri
output acrName string = acr.outputs.registryName
