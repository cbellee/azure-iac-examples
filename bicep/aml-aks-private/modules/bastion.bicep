param bastionName string
param bastionPublicIpName string
param tags object
param subnetId string
param location string

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
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
    enableTunneling: true
    disableCopyPaste: false
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
