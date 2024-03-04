param location string
param subnetId string

var suffix = uniqueString(resourceGroup().id)
var bastionName = 'bas-${suffix}'
var bastionPublicIpName = 'bas-pip-${suffix}'

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

resource bastion 'Microsoft.Network/bastionHosts@2021-05-01' = {
  location: location
  name: bastionName
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableFileCopy: true
    enableIpConnect: true
    disableCopyPaste: false
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
