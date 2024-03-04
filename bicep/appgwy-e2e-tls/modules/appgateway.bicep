param suffix string
param skuName string = 'Standard'
param gatewaySku object = {
  name: 'WAF_v2'
  tier: 'WAF_v2'
  capacity: '1'
}

param workspaceId string
param retentionInDays int = 30
param subnetId string

@secure()
param certPassword string

@secure()
param rootSslCert string

@secure()
param clientSslCert string

param frontEndPort int = 443
param requestTimeOut int = 180
param vmHostName string
param frontEndHostName string

var appGwyPipName = 'appgwy-pip-${suffix}'
var appGwyName = 'appgwy-${suffix}'

resource appGwyPip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: appGwyPipName
  location: resourceGroup().location
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
  location: resourceGroup().location
  properties: {
    sku: gatewaySku
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip-config'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: 'root-cert'
        properties: {
          data: rootSslCert
        }
      }
    ]
    sslCertificates: [
      {
        name: 'client-cert'
        properties: {
          data: clientSslCert
          password: certPassword
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontend-ip-config'
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
        name: 'vm-backend-pool'
        properties: {
          backendAddresses: [
            {
              fqdn: vmHostName
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
        name: 'vm-http-settings'
        properties: {
          port: frontEndPort
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          //hostName: vmHostName
          requestTimeout: requestTimeOut
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', appGwyName, 'root-cert')
            }
          ]
/*           probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGwyName, 'vm-probe')
          } */
        }
      }
    ]
    httpListeners: [
      {
        name: 'vm-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwyName, 'frontend-ip-config')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwyName, 'frontend-port')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwyName, 'client-cert')
          }
          hostName: frontEndHostName
          requireServerNameIndication: true
          customErrorConfigurations: []
        }
      }
    ]
    /*     urlPathMaps: [
      {
        name: 'vm-urlpathmapconfig'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'vm-backend-pool')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'vm-http-settings')
          }
          pathRules: [
            {
              name: 'external'
              properties: {
                paths: [
                  '/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'vm-backend-pool')
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'vm-http-settings')
                }
              }
            }
          ]
        }
      }
    ] */
    requestRoutingRules: [
      {
        name: 'vm-request-routing-rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwyName, 'vm-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwyName, 'vm-backend-pool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwyName, 'vm-http-settings')
          }
          /*           urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGwyName, 'vm-urlpathmapconfig')
          } */
        }
      }
    ]
/*     probes: [
      {
        name: 'vm-probe'
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
    ] */
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
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
