param subnetId string

var bastionName = '${uniqueString(resourceGroup().id)}-bas'
var bastionVipName = '${uniqueString(resourceGroup().id)}-bas-vip'

resource bastionVip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: resourceGroup().location
  name: bastionVipName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: bastionName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          publicIPAddress: {
            id: bastionVip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
