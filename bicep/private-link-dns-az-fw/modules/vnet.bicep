param vnetName string
param vnetAddressPrefix string
param subnets array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
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
      }
    }]
  }
}

output id string = virtualNetwork.id
output subnetArray array = virtualNetwork.properties.subnets
output vnetName string = virtualNetwork.name
