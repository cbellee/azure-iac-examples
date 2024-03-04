param locations array = [
  'australiaeast'
  'eastasia'
]
param colours array = [
  'blue'
  'green'
]
param prefix string
param imageName string
param imageTag string
param isMTLSEnabled bool = false
param keyVaultResourceGroupName string
param publicDnsResourceGroup string
param subDomainName string
param vnetAddressPrefixes array = [
  '10.0.0.0/16'
  '10.1.0.0/16'
]
param loadBalancerName string = 'kubernetes-internal'
param publicDomainName string
param keyVaultName string

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = [for location in locations: {
  name: '${prefix}-${location}-rg'
  location: location
}]

resource afdResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-global-rg'
  location: locations[0]
}

module vnet 'modules/vnet.bicep' = [for (location, index) in locations: {
  name: 'module-vnet-${location}'
  scope: resourceGroup[index]
  params: {
    location: location
    prefix: prefix
    vnetAddressPrefix: vnetAddressPrefixes[index]
  }
}]

module wks './modules/wks.bicep' = [for (location, index) in locations: {
  name: 'module-law-${location}'
  scope: resourceGroup[index]
  params: {
    location: location
    prefix: prefix
  }
}]

module appEnv 'modules/appEnvironment.bicep' = [for (location, index) in locations: {
  name: 'module-containerenv-${location}'
  scope: resourceGroup[index]
  params: {
    location: location
    vnetName: vnet[index].outputs.name
    workspaceName: wks[index].outputs.name
    isMTLSEnabled: isMTLSEnabled
    isZoneRedundant: !empty(pickZones('Microsoft.App', 'managedEnvironments', location)) ? true : false
    prefix: prefix
  }
}]

module containerApp 'modules/containerApp.bicep' = [for (location, index) in locations: {
  name: 'module-containerapp-${location}'
  scope: resourceGroup[index]
  params: {
    environmentId: appEnv[index].outputs.id
    imageName: imageName
    location: location
    prefix: prefix
    targetPort: 80
    colour: colours[index]
    imageTag: imageTag
  }
}]

module privateLinkService './modules/pls.bicep' = [for (location, index) in locations: {
  name: 'module-pls-${location}'
  scope: resourceGroup[index]
  params: {
    defaultDomain: split(appEnv[index].outputs.defaultDomain, '.')
    loadBalancerName: loadBalancerName
    location: location
    subnetId: vnet[index].outputs.subnets[1].id
    subscriptionId: subscription().subscriptionId
    prefix: prefix
  }
}]

module dnsZone './modules/dnsZone.bicep' = [for (location, index) in locations: {
  name: 'module-dnszone-${location}'
  scope: resourceGroup[index]
  params: {
    acaEnvironmentDomainName: appEnv[index].outputs.defaultDomain
    acaIlbIpAddress: appEnv[index].outputs.staticIp
    dnsZoneName: '${location}.azurecontainerapps.io'
    vnetName: vnet[index].outputs.name
  }
}]

module afd 'modules/afd.bicep' = {
  name: 'module-afd'
  scope: afdResourceGroup
  params: {
    keyVaultResourceGroupName: keyVaultResourceGroupName
    prefix: prefix
    wafMode: 'Detection'
    dnsZoneName: publicDomainName
    keyVaultName: keyVaultName
    externalDomainResourceGroupName: 'external-dns-zones-rg'
    publicDomainName: publicDomainName
    subDomainName: subDomainName
    location: locations[0]
  }
  dependsOn: [
    containerApp
    privateLinkService
  ]
}

@batchSize(1)
module afdOrigin 'modules/afdOrigin.bicep' = [for (location, index) in locations: {
  name: 'module-afdorigin-${location}'
  scope: afdResourceGroup
  params: {
    frontDoorName: afd.outputs.name
    containerAppFqdn: containerApp[index].outputs.fqdn
    location: location
    privateLinkServiceId: privateLinkService[index].outputs.id
  }
  dependsOn: [
    afd
  ]
}]

module afdRoute 'modules/afdRoute.bicep' = {
  name: 'module-afdRoute'
  scope: afdResourceGroup
  params: {
    endpointName: afd.outputs.endpointName
    frontDoorName: afd.outputs.name
    originGroupName: afdOrigin[0].outputs.originGroupName
    customDomainResourceName: afd.outputs.customDomainResourceName
  }
  dependsOn: [
    afdOrigin
  ]
}

module getPrivateEndpointCxnName 'modules/getPrivateEndpointCxn.bicep' = [for (location, index) in locations: {
  name: 'module-getPrivateEndpointCxnName-${location}'
  scope: resourceGroup[index]
  params: {
    privateLinkServiceName: privateLinkService[index].outputs.name
  }
  dependsOn: [
    afdOrigin
  ]
}]

module approvePrivateEndpointCxn 'modules/approvePrivateEndpointCxn.bicep' = [for (location, index) in locations: {
  name: 'module-approvePrivateEndpointCxn-${location}'
  scope: resourceGroup[index]
  params: {
    privateLinkServiceName: privateLinkService[index].outputs.name
    privateEndpointCxnName: getPrivateEndpointCxnName[index].outputs.peCxnName
  }
  dependsOn: [
    getPrivateEndpointCxnName
    privateLinkService
  ]
}]

module dnsCNAMERecord 'modules/dnsRecord.bicep' = {
  name: 'module-dnsCNAMERecord'
  scope: az.resourceGroup(publicDnsResourceGroup)
  params: {
    afdEndpointFqdn: afd.outputs.fqdn
    zoneName: publicDomainName
  }
}

output frontDoorEndpointFqdn string = afd.outputs.fqdn
output publicAfdEndpointDomainName string = 'gateway.${publicDomainName}'
