param location string
param windowsBackendHostName string
param linuxBackendHostName string
param linuxFrontEndHostName string
param windowsFrontendHostName string
param linuxBackendIpAddresses array
param windowsBackendIpAddress string
param trustedRootCertName string = 'trusted-root-cert'
param trustedRootCertId string 
param minCapacity int = 2
param maxCapacity int = 10
param frontendPort int = 443
param backendPort int
param userAssignedManagedIdentityResourceId string
param subnetId string

@secure()
param publicPfxCertSecretId string

@allowed([
  'Standard_v2'
  'WAF_v2'
])
param gatewaySku string

var suffix = uniqueString(resourceGroup().id)
var publicIpName = 'pip-${suffix}'
var applicationGatewayName = 'appgwy-${suffix}'
var wafPolicyName = 'waf-poli-${suffix}'
var certName = 'app-ssl-cert'

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
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
      '${userAssignedManagedIdentityResourceId}': {}
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
    sslCertificates: [
      {
        name: certName
        properties: {
          keyVaultSecretId: publicPfxCertSecretId
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: trustedRootCertName
        properties: {
          keyVaultSecretId: trustedRootCertId
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
            id: publicIp.id
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
        name: 'windowsBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: windowsBackendIpAddress
            }
          ]
        }
      }
      {
        name: 'linuxBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: linuxBackendIpAddresses[0]
            }
            {
              ipAddress: linuxBackendIpAddresses[1]
            }
          ]
        }
      }
    ]
    probes: []
    backendHttpSettingsCollection: [
      {
        name: 'windowsBackendHttpsSettings'
        properties: {
          port: backendPort
          protocol: 'Https'
          pickHostNameFromBackendAddress: false
          hostName: windowsBackendHostName
        }
      }
      {
        name: 'linuxBackendHttpsSettings'
        properties: {
          port: backendPort
          protocol: 'Https'
          pickHostNameFromBackendAddress: false
          hostName: linuxBackendHostName
        }
      }
    ]
    httpListeners: [
      {
        name: 'apacheListener'
        properties: {
          hostName: linuxFrontEndHostName
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
      {
        name: 'iisListener'
        properties: {
          hostName: windowsFrontendHostName
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
        name: 'windows_https_rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'iisListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'windowsBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'windowsBackendHttpsSettings')
          }
        }
      }
      {
        name: 'linux_https_rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'apacheListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'linuxBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'linuxBackendHttpsSettings')
          }
        }
      }
    ]
  }
}

output appGatewayFrontEndIpAddressId string = publicIp.id
output appGatewayFrontEndIpAddress string = publicIp.properties.ipAddress
