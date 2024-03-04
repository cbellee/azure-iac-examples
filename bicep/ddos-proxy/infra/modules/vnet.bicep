param vnetAddressPrefixes array
param subnetArray array
param vnetName string
param enableDdosProtection bool = false
param enableVmProtection bool = false
param dnsServers array = [
  '168.63.129.16'
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: vnetAddressPrefixes
    }
    enableDdosProtection: enableDdosProtection
    enableVmProtection: enableVmProtection
    dhcpOptions: {
      dnsServers: dnsServers
    }
    subnets: subnetArray
  }
}

output subnetList array = [for (subnet, i) in subnetArray: {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
}]

output vnetResourceId string = virtualNetwork.id
