param localVnetName string
param remoteVnetId string
param remoteVnetName string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${localVnetName}/${localVnetName}-to-${remoteVnetName}-peer'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
  }
}
