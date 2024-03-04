param virtualNetworks array
param tags object
param location string
param vmAdminUserName string = 'localadmin'
param vmAdminPassword string 

var suffix = uniqueString(resourceGroup().id)

module virtualNetworkModule './modules/vnets.bicep' = {
  name: 'vNetDeployment'
  params: {
    location: location
    suffix: suffix
    tags: tags
    vNet: virtualNetworks[0]
  }
}

module bastionModule './modules/bastion.bicep' = {
  dependsOn: [
    virtualNetworkModule
  ]
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: virtualNetworkModule.outputs.subnetRefs[0].id
    suffix: suffix
  }
}

module vmModule './modules/winvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'vmDeployment'
  params: {
    adminPassword: vmAdminPassword
    adminUserName: vmAdminUserName
    location: location
    subnetId: virtualNetworkModule.outputs.subnetRefs[3].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
    windowsOSVersion: '2019-Datacenter'
  }
}

module funcAppModule './modules/func.bicep' = {
  name: 'funcAppModule'
  params: {
    subnets: virtualNetworkModule.outputs.subnetRefs
    appSvcPrivateDNSZoneName: 'azurewebsites.net'
    vnetId: virtualNetworkModule.outputs.vnetRef
    location: location
    privateEndpointSubnetId: virtualNetworkModule.outputs.subnetRefs[1].id
    suffix: suffix
    tags: tags
    vnetIntegrationSubnetId: virtualNetworkModule.outputs.subnetRefs[2].id
  }
}
