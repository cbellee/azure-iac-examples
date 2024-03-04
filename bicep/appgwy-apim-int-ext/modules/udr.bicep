param suffix string
param azureFirewallPrivateIpAddress string

resource hubToSpokeRouteTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'hub-to-spoke-rt-${suffix}'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'hub-to-spoke-route'
        properties: {
          addressPrefix: '10.2.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIpAddress
        }
      }
    ]
  }
}

resource SpokeToHubRouteTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'spoke-to-hub-rt-${suffix}'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'spoke-to-hub-route'
        properties: {
          addressPrefix: '10.1.0.0/16'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azureFirewallPrivateIpAddress
        }
      }
    ]
  }
}

resource defaultFirewallRoute 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'default-firewall-rt-${suffix}'
  location: resourceGroup().location
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

resource appGwyFirewallRoute 'Microsoft.Network/routeTables@2021-02-01' = {
  name: 'appgwy-firewall-rt-${suffix}'
  location: resourceGroup().location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'appgwy-fw-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
  }
}
