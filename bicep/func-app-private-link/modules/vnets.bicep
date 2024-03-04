param vNet object
param tags object
param suffix string
param location string

var subnets = [for i in range(0, length(vNet.subnets)): {
  name: vNet.subnets[i].name
  properties: {
    addressPrefix: vNet.subnets[i].addressPrefix
    routeTable: ((vNet.subnets[i].udrName == json('null')) ? json('null') : json('{"id": "${resourceId('Microsoft.Network/routeTables', '${vNet.subnets[i].udrName}-rt-${suffix}')}"}"}'))
    networkSecurityGroup: ((vNet.subnets[i].nsgName == json('null')) ? json('null') : json('{"id": "${resourceId('Microsoft.Network/networkSecurityGroups', '${vNet.subnets[i].nsgName}-nsg-${suffix}')}"}"}'))
    delegations: ((vNet.subnets[i].delegations == json('null')) ? json ('null') : json('[{"name": "serviceDelegation", "properties": {"serviceName": "${vNet.subnets[i].delegations}"}}]'))
    privateEndpointNetworkPolicies: vNet.subnets[i].privateEndpointNetworkPolicies
  }
  id: resourceId('Microsoft.Network/virtualNetworks/subnets/', '${vNet.name}-${suffix}', vNet.subnets[i].name)
}]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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

output subnetRefs array = virtualNetwork.properties.subnets
output vnetRef string = virtualNetwork.id
output vnetName string = virtualNetwork.name
