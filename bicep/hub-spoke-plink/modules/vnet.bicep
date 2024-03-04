param vnetName string
param vnetAddressPrefix string
param subnets array
param tags object

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  tags: tags
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        privateEndpointNetworkPolicies: 'Disabled'
        delegations: any((subnet.delegations == []) ? null: subnet.delegations)
      } 
    }]
  }
}

output id string = virtualNetwork.id
output subnetArray array = virtualNetwork.properties.subnets
output vnetName string = virtualNetwork.name
