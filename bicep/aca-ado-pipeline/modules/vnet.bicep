param location string
param prefix string
param vnetAddressPrefix string

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'infrastructure-subnet'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 0)
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'privatelinkservice-subnet'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressPrefix, 22, 1)
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output subnets array = vnet.properties.subnets
output name string = vnet.name
output id string = vnet.id

