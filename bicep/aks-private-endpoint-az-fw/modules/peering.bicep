@description('naming suffix based on resource group name hash')
param suffix string

@description('array of JSON virtual network objects')
param vNets array
param isGatewayDeployed bool = false

resource hub_peering_to_spoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2018-11-01' = [for i in range(0, (length(vNets) - 1)): {
  name: '${vNets[0].name}-${suffix}/peering-to-${vNets[(i + 1)].name}-${suffix}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: isGatewayDeployed
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', '${vNets[(i + 1)].name}-${suffix}')
    }
  }
}]

resource spoke_peering_to_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2018-11-01' = [for i in range(0, (length(vNets) - 1)): {
  name: '${vNets[(i + 1)].name}-${suffix}/peering-to-${vNets[0].name}-${suffix}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: isGatewayDeployed
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', '${vNets[0].name}-${suffix}')
    }
  }
}]
