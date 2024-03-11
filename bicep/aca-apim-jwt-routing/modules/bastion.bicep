param location string
param vnetId string
param subnetId string

var suffix = uniqueString(resourceGroup().id)
var bastionName = 'bastion-${suffix}'
var bastionVipName = 'bastion-vip-${suffix}'

resource vip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: bastionVipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableFileCopy: true
    enableTunneling: true
    ipConfigurations: [
      {
        id: vip.id
        name: 'bastion-ipconfig'
        properties: {
          publicIPAddress: {
            id: vip.id
          }
          subnet: {
              id: subnetId
          }
        }
      }
    ]
    virtualNetwork: {
      id: vnetId
    }
  }
}
