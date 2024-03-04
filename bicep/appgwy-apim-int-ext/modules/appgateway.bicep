param suffix string
param skuName string = 'Standard'
param apimPrivateIpAddress string
param location string
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param privateDnsZoneName string
param workspaceId string
param retentionInDays int = 30
param subnetId string

@secure()
param apimGatewaySslCert string

@secure()
param apimGatewaySslCertPassword string

@secure()
param rootSslCert string
param frontEndPort int = 443
param internalFrontendPort int = 8080
param requestTimeOut int = 180
param externalProxyHostName string
param externalPortalHostName string
param externalManagementHostName string
param internalProxyHostName string
param internalPortalHostName string
param internalManagementHostName string

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
  properties: {
    sku: gatewaySku
    trustedRootCertificates: [
      {
        name: 'root-cert'
        properties: {
          data: rootSslCert
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
        name: 'apim-proxy-cert'
        properties: {
          data: apimGatewaySslCert
          password: apimGatewaySslCertPassword
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
    trustedClientCertificates: [
      {
        name: 'rootCACert'
        properties: {
          data: rootSslCert
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim-proxy-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: internalProxyHostName
            }
          ]
        }
      }
      {
        name: 'apim-portal-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: internalPortalHostName
            }
          ]
        }
      }
      {
        name: 'apim-management-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: internalManagementHostName
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
        name: 'apim-proxy-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: internalProxyHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            }
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-proxy-probe')
          }
        }
      }
      {
        name: 'apim-management-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: internalManagementHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            }
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-management-probe')
          }
        }
      }
      {
        name: 'apim-portal-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          hostName: internalPortalHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            }
          ]
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'apim-portal-probe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'apim-proxy-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-proxy-cert')
          }
          hostName: externalProxyHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      {
        name: 'apim-management-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-proxy-cert')
          }
          hostName: externalManagementHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      {
        name: 'apim-portal-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-proxy-cert')
          }
          hostName: externalPortalHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
      {
        name: 'apim-proxy-internal-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'internal-frontend')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'internal-frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'apim-proxy-cert')
          }
          hostName: internalProxyHostName
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
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-proxy-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-proxy-http-settings')
          }
          pathRules: [
            {
              name: 'external'
              properties: {
                paths: [
                  '/external/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-proxy-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-proxy-http-settings')
                }
              }
            }
          ]
        }
      }
      /* {
        name: 'apim-management-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-management-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-management-http-settings')
          }
          pathRules: [
            {
              name: 'management'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-management-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-management-http-settings')
                }
              }
            }
          ]
        }
      }
      {
        name: 'apim-portal-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-portal-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-portal-http-settings')
          }
          pathRules: [
            {
              name: 'portal'
              properties: {
                paths: [
                  '/'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-portal-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-portal-http-settings')
                }
              }
            }
          ]
        }
      } */
      {
        name: 'apim-internal-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-proxy-backend')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-proxy-http-settings')
          }
          pathRules: [
            {
              name: 'internal'
              properties: {
                paths: [
                  '/internal/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-proxy-backend')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-proxy-http-settings')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apim-proxy-external-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-proxy-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'apim-external-urlpathmapconfig')
          }
        }
      }
      {
        name: 'apim-portal-rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-portal-listener')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-portal-http-settings')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-portal-backend')
          }
        }
      }
      {
        name: 'apim-management-rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-management-listener')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'apim-management-http-settings')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'apim-management-backend')
          }
        }
      }
      {
        name: 'apim-proxy-internal-rule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'apim-proxy-internal-listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'apim-internal-urlpathmapconfig')
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
