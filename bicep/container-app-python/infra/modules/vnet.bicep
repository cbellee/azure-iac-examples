param location string
param subnets array
param name string
param addressSpace string

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: ((subnet.delegations == json('null')) ? json('null') : subnet.delegations)
        privateLinkServiceNetworkPolicies: 'Disabled'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    }]
  }
}

output vnet object = {
  name: vnet.name
  location: vnet.location
  subnets: vnet.properties.subnets
  addressSpace: vnet.properties.addressSpace
  id: vnet.id
}
