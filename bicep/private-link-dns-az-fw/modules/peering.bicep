param localVnetName string
param localVnetId string
param localVnetFriendlyName string
param remoteVnetName string
param remoteVnetId string
param remoteVnetFriendlyName string

resource vnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${localVnetName}/peering-to-${remoteVnetFriendlyName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}

resource vnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${remoteVnetName}/peering-to-${localVnetFriendlyName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: localVnetId
    }
  }
}

