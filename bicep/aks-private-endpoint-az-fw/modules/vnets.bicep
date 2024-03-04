@description('location to deploy the storage account')
param location string
param suffix string
param vNet object
param tags object

var subnets = [for i in range(0, length(vNet.subnets)): {
  name: vNet.subnets[i].name
  properties: {
    addressPrefix: vNet.subnets[i].addressPrefix
    routeTable: ((vNet.subnets[i].udrName == json('null')) ? json('null') : json('{"id": "${resourceId('Microsoft.Network/routeTables', '${vNet.subnets[i].udrName}-rt-${suffix}')}"}"}'))
    networkSecurityGroup: ((vNet.subnets[i].nsgName == json('null')) ? json('null') : json('{"id": "${resourceId('Microsoft.Network/networkSecurityGroups', '${vNet.subnets[i].nsgName}-nsg-${suffix}')}"}"}'))
    privateEndpointNetworkPolicies: ((vNet.subnets[i].privateEndpointNetworkPolicies == json('null')) ? json('null') : vNet.subnets[i].privateEndpointNetworkPolicies)
    privateLinkServiceNetworkPolicies: ((vNet.subnets[i].privateLinkServiceNetworkPolicies == json('null')) ? json('null') : vNet.subnets[i].privateLinkServiceNetworkPolicies)
  }
  id: resourceId('Microsoft.Network/virtualNetworks/subnets/', '${vNet.name}-${suffix}', vNet.subnets[i].name)
}]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2018-11-01' = {
  name: '${vNet.name}-${suffix}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: vNet.addressPrefixes
    }
    subnets: subnets
  }
}

output subnetRefs array = subnets
output vnetRef string = virtualNetwork.id
output vnetName string = '${vNet.name}-${suffix}'
