param remoteVnetName string
param localVnetName string
param remoteSubscriptionId string
param remoteResourceGroupName string

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: '${localVnetName}/${localVnetName}-to-${remoteVnetName}'
  properties: {
    remoteVirtualNetwork: {
      id: resourceId(remoteSubscriptionId, remoteResourceGroupName, 'Microsoft.Network/virtualNetworks', remoteVnetName)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
