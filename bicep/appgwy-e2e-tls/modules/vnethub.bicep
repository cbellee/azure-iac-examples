param tags object
param suffix string

var vnetName = 'hub-vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AppGatewaySubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          delegations: []
          networkSecurityGroup: {
            id: toLower(resourceId('Microsoft.Network/networkSecurityGroups', 'appGateway-subnet-nsg-${suffix}'))
          }
          serviceEndpoints: []
        }
      }
      {
        name: 'InfraSubnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          delegations: []
          serviceEndpoints: []
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          delegations: []
          serviceEndpoints: []
          networkSecurityGroup: {
            id: toLower(resourceId('Microsoft.Network/networkSecurityGroups', 'bastion-subnet-nsg-${suffix}'))
          }
        }
      }
    ]
  }
}

output vnet object = {
  subnetRefs: vnet.properties.subnets
  vnetName: vnet.name
  vnetRef: vnet.id
}
