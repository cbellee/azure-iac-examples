@description('location to deploy the storage account')
param location string
param udrName string
param azureFirewallPrivateIpAddress string

resource default_firewall_rt 'Microsoft.Network/routeTables@2023-04-01' = {
  name: udrName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-fw-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIpAddress
        }
      }
    ]
  }
}
