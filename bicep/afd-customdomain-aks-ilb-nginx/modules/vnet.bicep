param location string
param addressPrefix string
param subnets array
param tags object
param prefix string

var affix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-vnet-${affix}'

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
    subnets: [for (subnet, index) in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: cidrSubnet(addressPrefix, 24, index)
        privateLinkServiceNetworkPolicies: 'Disabled'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

output subnets array = vnet.properties.subnets
output vnetId string = vnet.id
output vnetName string = vnet.name
