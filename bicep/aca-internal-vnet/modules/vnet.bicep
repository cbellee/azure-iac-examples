param location string
param name string
param subnets array
param addressPrefixes array

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
    enableDdosProtection: false
  }
}

output name string = vnet.name
output subnets array = vnet.properties.subnets
output id string = vnet.id
