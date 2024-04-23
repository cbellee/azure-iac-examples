param location string
param vnetName string
param subnetName string
param internalHostName string
param blueIngressPrivateIpAddress string
param greenIngressPrivateIpAddress string

var suffix = uniqueString(resourceGroup().id)
var umidName = 'umid-${suffix}'
var gatewayName = 'app-gwy-${suffix}'
var firewallPolicyName = 'app-gwy-firewall-policy-${suffix}'

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: umidName
  location: location
}

resource vnet 'Microsoft.ScVmm/virtualNetworks@2023-10-07' existing = {
  name: vnetName
}

resource applicationGatewayFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-09-01' = {
  name: firewallPolicyName
  location: location
  properties: {
    policySettings: {
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
      state: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-09-01' = {
  name: gatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umid.id}': {}
    }
  }
  tags: {
    EnhancedNetworkControl: 'True'
  }
  properties: {
    firewallPolicy: {
      id: applicationGatewayFirewallPolicy.id
    }
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 3
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.0.4.4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetName)
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'blue-pool'
        properties: {
          backendAddresses: [
            {
              ipAddress: blueIngressPrivateIpAddress
            }
          ]
        }
      }
      {
        name: 'green-pool'
        properties: {
          backendAddresses: [
            {
              ipAddress: greenIngressPrivateIpAddress
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          hostName: internalHostName
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', gatewayName, 'backend-probe')
        }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', gatewayName, 'appGatewayHttpListener')
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              gatewayName,
              'appGatewayFrontendIP'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', gatewayName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostNames: []
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'aks-routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', gatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', gatewayName, 'blue-pool')
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              gatewayName,
              'appGatewayBackendHttpSettings'
            )
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: 'backend-probe'
        properties: {
          protocol: 'Http'
          path: '/livez'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          port: 80
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
  }
}

output name string = applicationGateway.name
output privateIpAddress string = applicationGateway.properties.frontendIPConfigurations[0].properties.privateIPAddress
