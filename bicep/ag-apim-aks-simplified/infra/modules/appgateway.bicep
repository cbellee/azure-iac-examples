param suffix string
param skuName string = 'Standard'
param apimPrivateIpAddress string
param umidResourceId string
param location string
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param zones array = []
param privateDnsZoneName string
param workspaceId string
param retentionInDays int = 30
param subnetId string

@secure()
param tlsCertSecretId string

param frontEndPort int = 443
param internalFrontendPort int = 8080
param requestTimeOut int = 180
param externalGatewayHostName string
param internalGatewayHostName string
param kubernetesSpaIpAddress string

var appGwyPipName = 'appgwy-pip-${suffix}'
var appGwyName = 'appgwy-${suffix}'

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
  zones: zones
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umidResourceId}': {}
    }
  }
  properties: {
    sku: gatewaySku
    trustedRootCertificates: [
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
            id: appGwyPip.id
          }
        }
      }
      {
        name: 'internal-frontend'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: apimPrivateIpAddress
          subnet: {
            id: subnetId
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
    backendAddressPools: [
      {
        name: 'apim-gateway-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: internalGatewayHostName
            }
          ]
        }
      }
      {
        name: 'kubernetes-spa-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: kubernetesSpaIpAddress
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
        name: 'apim-gateway-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: internalGatewayHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: []
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-gateway-probe')
          }
        }
      }
      {
        name: 'kubernetes-spa-http-settings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: requestTimeOut
        }
      }
    ]
    httpListeners: [
      {
        name: 'apim-gateway-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'tls-certificate')
          }
          hostName: externalGatewayHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      {
        name: 'apim-gateway-internal-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'internal-frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'internal-frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'tls-certificate')
          }
          hostName: internalGatewayHostName
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
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-gateway-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-http-settings')
          }
          defaultRewriteRuleSet: {
            id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', appGwyName, 'cross-origin')
          }
          pathRules: [
            {
              name: 'api'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-gateway-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-http-settings')
                }
                rewriteRuleSet: {
                  id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', appGwyName, 'cross-origin')
                }
              }
            }
            {
              name: 'kubernetes-spa-config'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'kubernetes-spa-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'kubernetes-spa-http-settings')
                }
                rewriteRuleSet: {
                  id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', appGwyName, 'cross-origin')
                }
              }
            }
          ]
        }
      }
      {
        name: 'apim-internal-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-gateway-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-http-settings')
          }
          pathRules: [
            {
              name: 'internal'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-gateway-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-gateway-http-settings')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim-gateway-external-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-gateway-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'apim-external-urlpathmapconfig')
          }
        }
      }
      {
        name: 'apim-gateway-internal-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-gateway-internal-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'apim-internal-urlpathmapconfig')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apim-gateway-probe'
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
    ]
    rewriteRuleSets: [
      {
        name: 'cross-origin'
        properties: {
          rewriteRules: [
            {
              ruleSequence: 100
              conditions: []
              name: 'cross-origin-rewrite-rule'
              actionSet: {
                requestHeaderConfigurations: []
                responseHeaderConfigurations: [
                  {
                    headerName: 'Access-Control-Allow-Origin'
                    headerValue: 'https://api.aksdemo.kainiindustries.net'
                  }
                  {
                    headerName: 'Access-Control-Allow-Origin'
                    headerValue: 'http://localhost:3000'
                  }
                  {
                    headerName: 'Access-Control-Allow-Credentials'
                    headerValue: 'true'
                  }
                  {
                    headerName: 'Access-Control-Allow-Headers'
                    headerValue: '*'
                  }
                  {
                    headerName: 'Access-Control-Allow-Methods'
                    headerValue: '*'
                  }
                ]
              }
            }
          ]
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

resource appGwyPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource appGwyDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: appGwyPrivateDnsZone
  name: 'api'
  properties: {
    aRecords: [
      {
        ipv4Address: appGwy.properties.frontendIPConfigurations[1].properties.privateIPAddress
      }
    ]
    ttl: 3600
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
