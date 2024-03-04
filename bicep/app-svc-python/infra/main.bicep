param name string
param region string
param containerPort string
param imageNameAndTag string

// deploy Azure Container Registry
module acrModule 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: region
    name: name
  }
}

// Deploy vnet
module vnetModule 'modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: region
    name: name
    vnetAddressPrefix: '10.1.0.0/16'
    integrationSubnetAddressPrefix: '10.1.1.0/24'
    privateLinkSubnetAddressPrefix: '10.1.2.0/24'
  }
}

// create private DNS zone
resource storageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'global'
}

resource storageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.core.windows.net'
  location: 'global'
}

// link DNS zones to vnets
resource storageBlobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'blob-dns-zone-vnet-link'
  location: 'global'
  parent: storageBlobPrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetModule.outputs.vnetId
    }
  }
}

resource storageFilePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'file-dns-zone-vnet-link'
  location: 'global'
  parent: storageFilePrivateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetModule.outputs.vnetId
    }
  }
}

// create App service plans and apps per region
module appSvcModule 'modules/app.bicep' = {
  name: 'app-deployment'
  params: {
    location: region
    name: name
    acrName: acrModule.outputs.acrName
    containerPort: containerPort
    imageNameAndTag: imageNameAndTag
    vnetIntegrationSubnetId: vnetModule.outputs.integrationSubnetId
  }
}

// output app serice URL
output regionAppUrl string = '${appSvcModule.outputs.hostname}/info'
