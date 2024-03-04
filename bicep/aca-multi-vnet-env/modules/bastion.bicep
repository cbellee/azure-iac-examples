param location string
param bastionName string
param bastionPipName string
param subnetId string

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: location
  name: bastionPipName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  location: location
  name: bastionName
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableFileCopy: true
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

output name string = bastion.name
