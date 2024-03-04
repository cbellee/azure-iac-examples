param location string

var suffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'ag-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
          delegations: []
          networkSecurityGroup: {
            id: toLower(resourceId('Microsoft.Network/networkSecurityGroups', 'ag-subnet-nsg-${suffix}'))
          }
          serviceEndpoints: []
        }
      }
      {
        name: 'vm-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          delegations: []
          networkSecurityGroup: {
            id: toLower(resourceId('Microsoft.Network/networkSecurityGroups', 'vm-subnet-nsg-${suffix}'))
          }
          serviceEndpoints: []
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          delegations: []
          serviceEndpoints: []
        }
      }
    ]
  }
}

output subnetRefs array = vnet.properties.subnets
output vnetName string = vnet.name
output vntIdvnetRef string = vnet.id
