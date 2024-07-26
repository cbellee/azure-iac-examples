param location string
param suffix string
param addressPrefix string
param tags object

var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: location
  tags: tags
  name: vnetName
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'aks-system-subnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        }
      }
      {
        name: 'aks-user-subnet'
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 24, 1)
        }
      }
    ]
  }
}

output subnets array = vnet.properties.subnets
