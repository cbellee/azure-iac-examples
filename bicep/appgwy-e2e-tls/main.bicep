param domainName string
param tags object
param location string
param clientCert object
param rootCert object
param winVmPassword string
param pfxSecretId string
param scriptUri string
param pfxThumbprint string
param vmName string
param dateTimeStamp string
param storageAccountName string
param keyVaultName string

var privateDomainName = 'internal.${domainName}'
var frontEndHost = 'web'
var frontEndHostName = '${frontEndHost}.${domainName}'
var suffix = uniqueString(resourceGroup().id)

module azMonitorModule './modules/azmon.bicep' = {
  name: 'azureMonitorDeployment'
  params: {
    suffix: suffix
  }
}

module networkSecurityGroupModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    suffix: suffix
  }
}

module hubVirtualNetworkModule 'modules/vnethub.bicep' = {
  name: 'hubVnetDeployment'
  dependsOn: [
    networkSecurityGroupModule
  ]
  params: {
    suffix: suffix
    tags: tags
  }
}

module spokeVirtualNetworkModule 'modules/vnetspoke.bicep' = {
  name: 'spokeVnetDeployment'
  dependsOn: [
    networkSecurityGroupModule
  ]
  params: {
    suffix: suffix
    tags: tags
  }
}

module virtualNetworkPeeringModule './modules/peerings.bicep' = {
  dependsOn: [
    hubVirtualNetworkModule
    spokeVirtualNetworkModule
  ]
  name: 'vNetPeeringDeployment'
  params: {
    hubVnet: hubVirtualNetworkModule.outputs.vnet
    spokeVnet: spokeVirtualNetworkModule.outputs.vnet
  }
}

module bastionModule './modules/bastion.bicep' = {
  dependsOn: [
    virtualNetworkPeeringModule
  ]
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: toLower(resourceId('Microsoft.Network/virtualNetworks/subnets', 'hub-vnet-${suffix}', 'AzureBastionSubnet'))
    suffix: suffix
  }
}

module winVmModule './modules/winvm.bicep' = {
  dependsOn: [
    virtualNetworkPeeringModule
  ]
  name: 'winVmDeployment'
  params: {
    windowsOSVersion: '2016-Datacenter'
    dateTimeStamp: dateTimeStamp
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    storageAccountName: storageAccountName
    computerName: vmName
    location: location
    subnetId: toLower(resourceId('Microsoft.Network/virtualNetworks/subnets', 'spoke-vnet-${suffix}', 'WorkloadSubnet'))
    suffix: suffix
    vmSize: 'Standard_D2_v3'
    scriptUri: scriptUri
    pfxThumbprint: pfxThumbprint
    pfxSecretId: pfxSecretId
    keyVaultName: keyVaultName
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: privateDomainName
  properties: {}
}

resource privateDnsZoneHubLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'hublink'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: hubVirtualNetworkModule.outputs.vnet.vnetRef
    }
  }
}

resource privateDnsZoneSpokeLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'spokelink'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: spokeVirtualNetworkModule.outputs.vnet.vnetRef
    }
  }
}

module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    azMonitorModule
  ]
  name: 'applicationGatewayDeployment'
  params: {
    suffix: suffix
    workspaceId: azMonitorModule.outputs.workspaceId
    frontEndHostName: frontEndHostName
    vmHostName: '${winVmModule.outputs.hostName}.${privateDomainName}'
    frontEndPort: 443
    retentionInDays: 7
    clientSslCert: clientCert.CertValue
    certPassword: clientCert.CertPassword
    rootSslCert: rootCert.CertValue
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: hubVirtualNetworkModule.outputs.vnet.subnetRefs[0].id
  }
}

module publicDns './modules/publicdns.bicep' = {
  name: 'publicDnsDeployment'
  scope: resourceGroup('external-dns-zones-rg')
  params: {
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: frontEndHost
    zoneName: domainName
  }
}

module networkSecurityGroupUpdateModule './modules/nsg.bicep' = {
  name: 'nsgUpdateDeployment'
  params: {
    location: location
    suffix: suffix
  }
}

output appGwyName string = applicationGatewayModule.outputs.appGwyName
output appGwyId string = applicationGatewayModule.outputs.appGwyId
output appGwyFqdn string = applicationGatewayModule.outputs.appGwyPublicDnsName
output appGwyPublicIpAddress string = applicationGatewayModule.outputs.appGwyPublicIpAddress
