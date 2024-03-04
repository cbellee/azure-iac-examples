param location string
param suffix string
param addressPrefix string
param subnets array
param tags object

var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  location: location
  tags: tags
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

output subnets array = vnet.properties.subnets
