param frontEndHostName string
param minCapacity int = 2
param maxCapacity int = 10
param frontendPort int = 443
param backendPort int = 80
param pfxCert string
param pfxCertPassword string
param probePath string = '/'
param tags object
param subnetId string
@allowed([
  'Standard_v2'
  'WAF_v2'
])
param gatewaySku string
param location string = resourceGroup().location
@allowed([
  'Enabled'
  'Disabled'
])
param cookieBasedAffinity string = 'Disabled'

var prefix = uniqueString(resourceGroup().id)
var applicationGatewayName = '${prefix}-appgwy'
var appGwPublicIpName = '${applicationGatewayName}-pip'
var wafPolicyName = '${applicationGatewayName}-waf-policy'
var certName = 'ssl-cert'

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: appGwPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGatewayWafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2020-08-01' = {
  name: wafPolicyName
  location: resourceGroup().location
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
  tags: tags
  location: location
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
    sslCertificates: [
      {
        name: certName
        properties: {
          data: pfxCert
          password: pfxCertPassword
        }
      }
    ]
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
        name: 'frontendPort'
        properties: {
          port: frontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    probes: [
      {
        name: 'myAppProbe'
        properties: {
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          path: probePath
          pickHostNameFromBackendHttpSettings: true
          protocol: 'Http'
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
          port: backendPort
          protocol: 'Http'
          cookieBasedAffinity: cookieBasedAffinity
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'myAppProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'multiSiteListener'
        properties: {
          hostName: frontEndHostName
          requireServerNameIndication: true
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'frontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, certName)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'https_rule'
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

output appGatewayResourceId string = applicationGateway.id
output appGatewayFrontEndIpAddressId string = publicIP.id
output appGatewayFrontEndIpAddress string = publicIP.properties.ipAddress
output appGatewayBeAddressPoolResourceId string = resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'backendPool')
