param location string
param tags object
param vnetAddressPrefixes array = [
  '10.1.0.0/16'
]
param subnetAddressPrefix string = '10.1.0.0/24'

var suffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  tags: tags
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: [
      {
        name: 'vnetIntegrationSubnet'
        properties: {
          addressPrefix: subnetAddressPrefix
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Sql'
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output subnetIds array = vnet.properties.subnets
output vnetName string = vnet.name
