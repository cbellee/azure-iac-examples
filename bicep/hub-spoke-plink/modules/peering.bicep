param parentVnetName string
param remoteVnetId string
param remoteVnetName string
param useRemoteGateways bool = false

resource parentVnet 'Microsoft.Network/virtualNetworks@2020-08-01' existing = {
  name: parentVnetName
}

resource vnetPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  parent: parentVnet
  name: 'peering-to-${remoteVnetName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
