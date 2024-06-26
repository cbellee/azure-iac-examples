@allowed([
  'Standard_v2'
  'WAF_v2'
])
param applicationGatewaySKU string = 'WAF_v2'
param applicationGatewaySubnetId string
param tags object
param prefix string
param logAnalyticsWorkspaceId string
param location string = resourceGroup().location

var publicIpName = '${prefix}-appgwy-vip'
var applicationGatewayName = '${prefix}-appgwy'
var webApplicationFirewallConfiguration = {
  enabled: 'true'
  firewallMode: 'Detection'
}

resource applicationGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-06-01' = {
  name: applicationGatewayName
  location: location
  tags: tags
  properties: {
    sku: {
      name: applicationGatewaySKU
      tier: applicationGatewaySKU
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: applicationGatewayPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendHttpPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'appGatewayFrontendHttpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          protocol: 'Http'
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendHttpPort')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIp')
          }
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: ((applicationGatewaySKU == 'WAF_v2') ? webApplicationFirewallConfiguration : null)
  }
}

resource appGwyDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: applicationGateway
  name: 'appGwyDiagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output applicationGatewayId string = applicationGateway.id
output applicationGatewayName string = applicationGateway.name
output applicationGatewayPublicIpResourceId string = applicationGatewayPublicIp.id
