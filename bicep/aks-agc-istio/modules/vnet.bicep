param location string
param vnetAddressSpace string = '10.1.0.0/16'

var suffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'node-subnet'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressSpace, 24, 0)
        }
      }
      {
        name: 'agc-subnet'
        properties: {
          addressPrefix: cidrSubnet(vnetAddressSpace, 24, 1)
          delegations: [
            {
              name: 'agc-delegation'
              type: 'Microsoft.ServiceNetworking/trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
    ]
  }
}

output nodeSubnetId string = vnet.properties.subnets[0].id
output podSubnetId string = vnet.properties.subnets[1].id
output vnetName string = vnet.name
output nodeSubnetName string = vnet.properties.subnets[0].name
output agcSubnetName string = vnet.properties.subnets[1].name
output agcSubnetId string = vnet.properties.subnets[1].id

