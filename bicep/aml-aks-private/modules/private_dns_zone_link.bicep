param privateDnsZoneName string
param vnetName string
param vnetRef string

resource dnsZone 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDnsZoneName}/${vnetName}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnetRef
    }
    registrationEnabled: false
  }
}
