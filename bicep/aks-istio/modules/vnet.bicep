param location string
param vnetName string
param aksSubnetName string = 'k8s-subnet'
param appGatewaySubnetName string = 'gwy-subnet'
param vmSubnetName string = 'vm-subnet'
param aksSubnetAddressPrefix string = '192.168.0.0/22'
param appGatewaySubnetAddressPrefix string = '192.168.4.0/24'
param vmSubnetAddressPrefix string = '192.168.5.0/24'


resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetAddressPrefix
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetAddressPrefix
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
output appGatewaySubnetName string = appGatewaySubnetName
