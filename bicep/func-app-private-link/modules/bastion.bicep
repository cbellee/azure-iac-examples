param location string
param suffix string
param subnetId string

var bastionName = 'bst-${suffix}'
var bastionPublicIpName = 'bst-pip-${suffix}'

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: bastionPublicIpName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-02-01' = {
  location: location
  name: bastionName
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}
