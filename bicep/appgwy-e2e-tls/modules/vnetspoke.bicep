param tags object
param suffix string

var vnetName = 'spoke-vnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: resourceGroup().location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'WorkloadSubnet'
        properties: {
          addressPrefix: '10.2.1.0/24'
          delegations: []
          networkSecurityGroup: {
            id: toLower(resourceId('Microsoft.Network/networkSecurityGroups', 'workload-subnet-nsg-${suffix}'))
          }
          serviceEndpoints: []
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
