param location string
param name string
param addressPrefix string
param subnets array
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: location
  tags: tags
  name: name
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
output vnetId string = vnet.id
