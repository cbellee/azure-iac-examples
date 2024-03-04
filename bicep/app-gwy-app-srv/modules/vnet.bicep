param prefix string
param vnetAddressPrefix string
param subnets array

var virtualNetworkName = '${prefix}-vnet'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
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
        serviceEndpoints: [
          {
            locations: [
              '*'
            ]
            service: subnet.serviceEndpoint
          }
        ]
      }
    }]
  }
}

output appGatewaySubnetId string = virtualNetwork.properties.subnets[0].id
