param virtualNetwork object

var suffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetwork.addressPrefixes
    }
    subnets: [for subnet in virtualNetwork.subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
        delegations: any((subnet.delegations == []) ? null : subnet.delegations)
      }
    }]
  }
}

output vnetId string = vnet.id
output subnetIds array = vnet.properties.subnets
output vnetName string = vnet.name
