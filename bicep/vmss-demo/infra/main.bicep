param adminUsername string
param adminPassword string
param vmssInstanceCount int
param pfxCert string
param location string
param pfxCertPassword string
param appGwyHostName string
param sshPublicKey string
param vmssCustomScriptUri string
param dnsResourceGroupName string = 'external-dns-zones-rg'
param dnsZoneName string = 'kainiindustries.net'
param dnsARecordName string = 'myapp'
param forceScriptUpdate int
param storageAccountName string

var prefix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-vnet'
var subnets = [
  {
    name: 'vmss-subnet'
    properties: {
      addressPrefix: '10.0.0.0/24'
    }
  }
  {
    name: 'vmss-ilb-subnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
    }
  }
  {
    name: 'app-gateway-subnet'
    properties: {
      addressPrefix: '10.0.2.0/24'
    }
  }
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: '10.0.3.0/24'
    }
  }
]

module azMonWks 'modules/azmon.bicep' = {
  name: 'azMonDeployment'
  params: {
    location: location
    suffix: prefix
  }
}

module vnetMod './modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
    vnetName: vnetName
    subnets: subnets
    vnetAddressPrefixes: [
      '10.0.0.0/16'
    ]
  }
}

module bastionmod './modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: vnetMod.outputs.subnetList[3].id
  }
}

module appGwyMod './modules/appGateway.bicep' = {
  name: 'appGwyDeployment'
  params: {
    location: location
    probePath: '/'
    gatewaySku: 'WAF_v2'
    pfxCert: pfxCert
    pfxCertPassword: pfxCertPassword
    frontEndHostName: appGwyHostName
    subnetId: vnetMod.outputs.subnetList[2].id
  }
}

module vmssMod './modules/vmss.bicep' = {
  name: 'vmssDeployment'
  params: {
    location: location
    sshPublicKey: sshPublicKey
    workspaceId: azMonWks.outputs.workspaceId
    workspaceKey: azMonWks.outputs.workspaceKey
    storageAccountName: storageAccountName
    appGatewayResourceId: appGwyMod.outputs.appGatewayResourceId
    forceScriptUpdate: forceScriptUpdate
    vmssExtensionCustomScriptUri: vmssCustomScriptUri
    appGatewayBePoolResourceId: appGwyMod.outputs.appGatewayBeAddressPoolResourceId
    instanceCount: vmssInstanceCount
    vmssSubnetId: vnetMod.outputs.subnetList[0].id
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

module dnsRecord './modules/dns.bicep' = {
  scope: resourceGroup(dnsResourceGroupName)
  name: 'dnsRecordDeployment'
  params: {
    dnsZoneName: dnsZoneName
    recordName: dnsARecordName
    appGatewayIpAddress: appGwyMod.outputs.appGatewayFrontEndIpAddress
  }
}

output appGatewayUri string = 'https://${appGwyMod.outputs.appGatewayFqdn}'
