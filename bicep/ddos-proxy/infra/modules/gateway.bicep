param virtualNetworkGatewayName string
param localNetworkAddressPrefixes array
param localGatewayIpAddress string
param publicIpAddressName string
param localNetworkGatewayName string
param gatewaySubnetResourceId string
param vpnSharedKey string
param tags object

var vpnCxnName = 'home-to-azure-s2s-vpn-cxn'

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-02-01' = {
  name: localNetworkGatewayName
  location: resourceGroup().location
  properties: {
    gatewayIpAddress: localGatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: localNetworkAddressPrefixes
    }
  }
  tags: tags
}

resource gatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpAddressName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2021-02-01' = {
  name: virtualNetworkGatewayName
  location: resourceGroup().location
  properties: {
    gatewayType: 'Vpn'
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: gatewaySubnetResourceId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayPublicIpAddress.id
          }
        }
      }
    ]
  }
  tags: tags
}

resource virtualNetworkGatewayCxn 'Microsoft.Network/connections@2021-02-01' = {
  name: vpnCxnName
  location: resourceGroup().location
  tags: tags
  properties: {
    virtualNetworkGateway1: {
      properties: {}
      id: virtualNetworkGateway.id
    }
    virtualNetworkGateway2: {
      properties: {}
      id: localNetworkGateway.id
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    sharedKey: vpnSharedKey
    routingWeight: 0
    enableBgp: false
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    expressRouteGatewayBypass: false
    dpdTimeoutSeconds: 0
  }
}
