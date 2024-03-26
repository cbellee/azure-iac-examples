param location string
param vnetName string
param aksSubnetName string = 'k8s-subnet'
param vmSubnetName string = 'vm-subnet'
param addressPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 22, 0)
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: cidrSubnet(addressPrefix, 22, 1)
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

output id string = vnet.id
output name string = vnet.name
output aksSubnetName string = aksSubnetName
