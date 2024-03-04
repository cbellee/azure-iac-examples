param suffix string
param tags object
param subnetId string
param location string

var bastionName = 'bastion-${suffix}'
var bastionPublicIpName = 'bastion-pip-${suffix}'

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

resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableFileCopy: true
    ipConfigurations: [
      {
        name: 'ipconfig-1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }

  tags: tags
}
