param prefix string
param skuName string = 'Standard'
param appGwySubnetId string
param location string
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param workspaceId string
param retentionInDays int = 30

param frontEndPort int = 443
param internalFrontendPort int = 8080
param requestTimeOut int = 180
param publicHostName string
param ilbAseHostName string

@secure()
param tlsCertSecretId string

var appGwyPipName = '${prefix}-appgwy-pip'
var appGwyName = '${prefix}-appgwy'

resource appGwyPip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: appGwyPipName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    dnsSettings: {
      domainNameLabel: appGwyName
    }
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource appGwy 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appGwyName
  location: location
  properties: {
    sku: gatewaySku
    trustedRootCertificates: [
    ]
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip'
        properties: {
          subnet: {
            id: appGwySubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'tls-cert'
        properties: {
          keyVaultSecretId: tlsCertSecretId
        }
      }
    ]
    sslProfiles: []
    authenticationCertificates: []
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGwyPip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontend-port'
        properties: {
          port: frontEndPort
        }
      }
      {
        name: 'internal-frontend-port'
        properties: {
          port: internalFrontendPort
        }
      }
    ]
    trustedClientCertificates: [
    ]
    backendAddressPools: [
      {
        name: 'ilb-ase-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: ilbAseHostName
            }
          ]
        }
      }
      {
        name: 'sinkpool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'ilb-ase-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: ilbAseHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
/*             {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            } */
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'ilb-ase-probe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'ilb-ase-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'tls-cert')
          }
          hostName: publicHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'apim-external-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'ilb-ase-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'ilb-ase-http-settings')
          }
          pathRules: [
            {
              name: 'default'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'ilb-ase-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'ilb-ase-http-settings')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'ilb-ase-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'ilb-ase-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'ilb-ase-urlpathmapconfig')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apim-proxy-probe'
        properties: {
          protocol: 'Https'
          path: '/status-0123456789abcdef'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
      {
        name: 'apim-management-probe'
        properties: {
          protocol: 'Https'
          path: '/ServiceStatus'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
      {
        name: 'apim-portal-probe'
        properties: {
          protocol: 'Https'
          path: '/signin'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      disabledRuleGroups: []
      exclusions: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    customErrorConfigurations: []
  }
}

resource appGwyDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'app-gwy-diagnostics'
  scope: appGwy
  properties: {
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    workspaceId: workspaceId
  }
}

output appGwyName string = appGwy.name
output appGwyId string = appGwy.id
output appGwyPublicDnsName string = appGwyPip.properties.dnsSettings.fqdn
output appGwyPublicIpAddress string = appGwyPip.properties.ipAddress
