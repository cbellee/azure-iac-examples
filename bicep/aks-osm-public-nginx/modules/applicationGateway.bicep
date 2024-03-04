param skuName string = 'Standard'
param umidResourceId string
param name string
param location string
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param workspaceId string
param retentionInDays int = 30
param subnetId string

@secure()
param tlsCertSecretId string

@secure()
param nginxTlsCertSecretId string

param frontEndPort int = 443
param requestTimeOut int = 180
param externalHostName string
param internalHostName string
param nginxBackendIpAddress string

var appGwyPipName = 'vip-${name}'

resource appGwyVip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: appGwyPipName
  location: location
  sku: {
    name: skuName
  }
  properties: {
    dnsSettings: {
      domainNameLabel: name
    }
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource appGwy 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umidResourceId}': {}
    }
  }
  properties: {
    sku: gatewaySku
    trustedRootCertificates: [
      {
        name: 'nginx-backend-root-certificate'
        properties: {
          keyVaultSecretId: nginxTlsCertSecretId
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'tls-certificate'
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
            id: appGwyVip.id
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
    ]
    backendAddressPools: [
      {
        name: 'nginx-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: nginxBackendIpAddress
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
        name: 'nginx-http-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: internalHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', name, 'nginx-backend-root-certificate')
            }
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', name, 'nginx-probe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'frontend-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', name, 'tls-certificate')
          }
          hostName: externalHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'nginx-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'nginx-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'nginx-http-settings')
          }
          pathRules: [
            {
              name: 'httpbin'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'nginx-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'nginx-http-settings')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'external-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'frontend-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', name, 'nginx-urlpathmapconfig')
          }
        }
      }
    ]
    probes: [
      {
        name: 'nginx-probe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {}
        }
      }
    ]
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

output name string = appGwy.name
output appGwyId string = appGwy.id
output appGwyPublicDnsName string = appGwyVip.properties.dnsSettings.fqdn
output appGwyPublicIpAddress string = appGwyVip.properties.ipAddress
