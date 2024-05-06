param location string = 'australiaeast'
param prefix string = 'cbellee'
param acrName string
param imageName string
param sshKey string
param colour string = 'blue'
param adminUserName string
param addressPrefixes array = ['10.0.0.0/16']
param subnets array = [
  {
    name: 'aca-subnet'
    properties: {
      addressPrefix: '10.0.0.0/23'
    }
  }
  {
    name: 'vm-subnet'
    properties: {
      addressPrefix: '10.0.4.0/24'
    }
  }
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: '10.0.5.0/24'
    }
  }
]

var suffix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-${suffix}-vnet'
var workspaceName = '${prefix}-${suffix}-wks'
var bastionName = '${prefix}-${suffix}-bas'
var bastionPipName = '${prefix}-${suffix}-bas-pip'
var appName = '${prefix}-${suffix}-app'
var appEnvironmentName = '${prefix}-${suffix}'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

targetScope = 'resourceGroup'

module vnet 'modules/vnet.bicep' = {
  name: 'aca-vnet-module'
  params: {
    location: location
    name: vnetName
    addressPrefixes: addressPrefixes
    subnets: subnets
  }
}

module umid 'modules/umid.bicep' = {
  name: 'umid-module'
  params: {
    location: location
    prefix: prefix
  }
}

module workspace 'modules/wks.bicep' = {
  name: 'wks-module'
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    bastionName: bastionName
    bastionPipName: bastionPipName
    location: location
    subnetId: vnet.outputs.subnets[2].id
  }
}

module appEnvironment 'modules/appEnvironment.bicep' = {
  name: 'app-environment-module'
  params: {
    location: location
    appEnvironmentName: '${appEnvironmentName}-env'
    workspaceName: workspace.outputs.name
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.outputs.name, vnet.outputs.subnets[0].name)
    isInternal: true
    isZoneRedundant: false
  }
  dependsOn: [
    workspace
  ]
}

module containerApp 'modules/containerApp.bicep' = {
  name: 'container-app-module'
  dependsOn: [
    workspace
    appEnvironment
  ]
  params: {
    umidName: umid.outputs.name
    colour: colour
    acrName: acrName
    targetPort: 80
    location: location
    appName: appName
    environmentId: appEnvironment.outputs.id
    imageName: imageName
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    prefix: prefix
  }
}

module vm 'modules/vm.bicep' = {
  name: 'vm-module'
  params: {
    adminUserName: adminUserName
    location: location
    sshKey: sshKey
    vnetName: vnet.outputs.name
    prefix: prefix
  }
  dependsOn: [
    dnsZoneLink
  ]
}

module dnsZone 'modules/privateDnsZone.bicep' = {
  name: 'dns-zone-module'
  params: {
    zoneName: appEnvironment.outputs.domainName
  }
}

module aRecord './modules/aRecord.bicep' = {
  name: 'a-record-module'
  params: {
    ipAddress: appEnvironment.outputs.ipAddress
    zoneName: dnsZone.outputs.name
  }
}

module dnsZoneLink 'modules/privateDnsZoneLink.bicep' = {
  name: 'dns-zone-link-module'
  params: {
    dnsZoneName: dnsZone.outputs.name
    vnetId: vnet.outputs.id
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('acrPullRole', umid.name, acr.name)
  properties: {
    principalId: umid.outputs.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
  }
  dependsOn: [
    umid
  ]
}

output vmId string = vm.outputs.id
output bastionName string = bastion.outputs.name
output appFqdn string = containerApp.outputs.fqdn
output acrName string = acr.outputs.name
