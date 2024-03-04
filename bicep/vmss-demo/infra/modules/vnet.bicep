param vnetAddressPrefixes array
param subnets array
param vnetName string
param location string 

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    subnets: subnets
  }
}

output subnetList array = [for (subnet, i) in subnets: {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
}]
