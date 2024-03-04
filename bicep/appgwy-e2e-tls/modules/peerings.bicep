param hubVnet object
param spokeVnet object

resource hubVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${hubVnet.vnetName}/peering-to-${spokeVnet.vnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.vnetRef
    }
  }
  dependsOn: []
}

resource spokeVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = {
  name: '${spokeVnet.vnetName}/peering-to-${hubVnet.vnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.vnetRef
    }
  }
  dependsOn: []
}
