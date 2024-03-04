@description('private dns zone name')
param privateDnsZoneName string

@description('virtual network name')
param virtualNetworkName string

@description('controls whether the dns zone will automatically register DNS records for resources in the virtual network')
param enableVmRegistration bool = false

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource privateDnsZoneName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: '${privateDnsZone}-${virtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: enableVmRegistration
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
  }
}
