// param frontEndHostName string
param userAssignedManagedIdentityId string
param hostName string
param minCapacity int = 1
param maxCapacity int = 3
param frontendHttpPort int = 80
param backendHttpPort int = 80
param probePath string = '/status-0123456789abcdef'
param subnetId string
param location string = resourceGroup().location

@allowed([
  'Standard_v2'
  'WAF_v2'
])
param gatewaySku string


@allowed([
  'Enabled'
  'Disabled'
])
param cookieBasedAffinity string = 'Disabled'

var backendAddresses = [
  {
    fqdn: hostName
  }
]

var suffix = uniqueString(resourceGroup().id)
var applicationGatewayName = 'appgwy-${suffix}'
var appGwPublicIpName = 'appgwy-pip-${suffix}'
var wafPolicyName = 'appgwy-waf-policy-${suffix}'

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: appGwPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGatewayWafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2020-08-01' = {
  name: wafPolicyName
  location: location
  properties: {
    managedRules: {
      exclusions: []
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
    policySettings: {
      fileUploadLimitInMb: 20
      maxRequestBodySizeInKb: 128
      mode: 'Prevention'
      requestBodyCheck: true
      state: 'Enabled'
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2020-06-01' = {
  name: applicationGatewayName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityId}': {}
    }
  }
  properties: {
    sku: {
      name: gatewaySku
      tier: gatewaySku
    }
    firewallPolicy: {
      id: applicationGatewayWafPolicy.id
    }
    autoscaleConfiguration: {
      minCapacity: minCapacity
      maxCapacity: maxCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIp'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendHttpPort'
        properties: {
          port: frontendHttpPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: backendAddresses
        }
      }
    ]
    probes: [
      {
        name: 'apimProbe'
        properties: {
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          path: probePath
          pickHostNameFromBackendHttpSettings: true
          protocol: 'Https'
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpsSettings'
        properties: {
          port: backendHttpPort
          protocol: 'Https'
          cookieBasedAffinity: cookieBasedAffinity
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'apimProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'multiSiteListener'
        properties: {
          // hostName: frontEndHostName
          // requireServerNameIndication: true
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'frontendHttpPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'http_rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'multiSiteListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'backendHttpsSettings')
          }
        }
      }
    ]
  }
}

output appGatewayFrontEndIpAddressId string = publicIP.id
output appGatewayFrontEndIpAddress string = publicIP.properties.ipAddress
