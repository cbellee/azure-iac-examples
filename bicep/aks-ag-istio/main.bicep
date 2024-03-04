param location string = 'australiaeast'
param aksVersion string = '1.27.1'
param umidName string
param privateDnsZoneName string
param istioGatewayARecordName string
param backendGatewayFqdn string = '${istioGatewayARecordName}.${privateDnsZoneName}'
param internalHostName string = 'internal.bellee.net'
param linuxAdminUserName string = 'azureuser'
param minNodes int = 1
param maxNodes int = 3
param maxPods int = 80
param vmSku string = 'Standard_D4ds_v5'
param sshPublicKey string
param aksSubnetName string = 'k8s-subnet'
param appGatewaySubnetName string = 'gwy-subnet'
param vmSubnetName string = 'vm-subnet'
param aksSubnetAddressPrefix string = '192.168.0.0/24'
param appGatewaySubnetAddressPrefix string = '192.168.1.0/24'
param vmSubnetAddressPrefix string = '192.168.2.0/24'
param publicHostName string
param dnsZoneName string
param dnsResourceGroupName string
param keyVaultName string
param acrName string

@secure()
param rootCertSecretId string

@secure()
param rootCACertData string

@secure()
param publicCertSecretId string

var affix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${affix}'
var publicIPAddressName = 'vip-${affix}'
var firewallPolicyName = 'fw-policy-${affix}'
var applicationGatewayName = 'agw-${affix}'
var aksClusterName = 'cluster-${affix}'
var wksName = 'wks-${affix}'
var aksUmidName = 'aks-umid'

resource aksUmid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: aksUmidName
  location: location
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
    vnetName: vnetName
    aksSubnetName: aksSubnetName
    appGatewaySubnetName: appGatewaySubnetName
    vmSubnetName: vmSubnetName
    aksSubnetAddressPrefix: aksSubnetAddressPrefix
    appGatewaySubnetAddressPrefix: appGatewaySubnetAddressPrefix
    vmSubnetAddressPrefix: vmSubnetAddressPrefix
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: wksName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks-module'
  params: {
    acrName: acrName
    aksClusterName: aksClusterName
    aksUmidName: aksUmidName
    aksVersion: aksVersion
    linuxAdminUserName: linuxAdminUserName
    location: location
    maxNodes: maxNodes
    maxPods: maxPods
    minNodes: minNodes
    sshPublicKey: sshPublicKey
    vmSku: vmSku
    vnetName: vnet.outputs.name
    subnetName: vnet.outputs.aksSubnetName
    workspaceId: wks.id
    aksWorkloadIdentityUmidName: 'aks-workload-identity-umid'
    keyVaultName: keyVaultName
  }
}

module aRecord 'modules/aRecord.bicep' = {
  name: 'aRecord-module'
  params: {
    aksNodeResourceGroup: aks.outputs.clusterResourceGroup
    gatewayARecordName: istioGatewayARecordName
    privateDnsZoneName: privateDnsZone.name
    albName: 'kubernetes-internal'
  }
}

module appGateway 'modules/appGateway.bicep' = {
  name: 'appGateway-module'
  params: {
    hostName: '${publicHostName}.${dnsZoneName}'
    subnetName: appGatewaySubnetName
    applicationGatewayName: applicationGatewayName
    firewallPolicyName: firewallPolicyName
    publicIPAddressName: publicIPAddressName
    backendGatewayFqdn: backendGatewayFqdn
    internalHostName: internalHostName
    location: location
    rootCACertData: rootCACertData
    rootCertSecretId: rootCertSecretId
    publicCertSecretId: publicCertSecretId
    umidName: umidName
    vnetName: vnet.outputs.name
  }
  dependsOn: [
    aRecord
  ]
}

resource privateDnsZonesVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: 'k8s-dns-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.outputs.id
    }
  }
}

module dns 'modules/dns.bicep' = {
  name: 'dns-module'
  scope: resourceGroup(dnsResourceGroupName)
  params: {
    hostName: publicHostName
    cname: appGateway.outputs.vipDnsName
    zoneName: dnsZoneName
  }
}

output aksClusterName string = aks.outputs.clusterName
output appGatewayName string = appGateway.outputs.name
output istioGatewayIpAddress string = aRecord.outputs.ilbIpAddress
output appGatewayPublicIpAddress string = appGateway.outputs.ipAddress
output workloadIdentityClientId string = aks.outputs.workloadIdentityClientId
output oidcIssuerUrl string = aks.outputs.oidcIssuerUrl
output workloadManagedIdentityName string = aks.outputs.workloadManagedIdentityName
output workloadManagedIdentityId string = aks.outputs.workloadManagedIdentityId
