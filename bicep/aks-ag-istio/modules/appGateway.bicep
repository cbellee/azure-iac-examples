param location string
param umidName string
param vnetName string
param subnetName string
param backendGatewayFqdn string
param internalHostName string
param publicIPAddressName string
param applicationGatewayName string
param firewallPolicyName string
param hostName string

@secure()
param rootCertSecretId string

@secure()
param rootCACertData string

@secure()
param publicCertSecretId string

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: umidName
}

resource vnet 'Microsoft.ScVmm/virtualNetworks@2022-05-21-preview' existing = {
  name: vnetName
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: publicIPAddressName
    }
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

resource applicationGatewayFirewallPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2023-02-01' = {
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

resource applicationGateway 'Microsoft.Network/applicationGateways@2022-11-01' = {
  name: applicationGatewayName
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
    sslCertificates: [
      {
        name: 'public-cert'
        properties: {
          keyVaultSecretId: publicCertSecretId
        }
      }
    ]
    trustedRootCertificates: [
      {
        name: 'root-cert'
        properties: {
          keyVaultSecretId: rootCertSecretId
        }
      }
    ]
    trustedClientCertificates: [
      {
        name: 'root-ca-cert'
        properties: {
          data: rootCACertData
        }
      }
    ]
    sslProfiles: [
      {
        name: 'ssl-profile'
        properties: {
          clientAuthConfiguration: {
            verifyClientCertIssuerDN: false
            verifyClientRevocation: 'None'
          }
          sslPolicy: {
            policyName: 'AppGwSslPolicy20150501'
            policyType: 'Predefined'
          }
          trustedClientCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedClientCertificates', applicationGatewayName, 'root-ca-cert')
            }
          ]
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: backendGatewayFqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          hostName: internalHostName
          pickHostNameFromBackendAddress: false
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'https-probe-01')
          }
          trustedRootCertificates: [
            {
              id: resourceId('Microsoft.Network/applicationGateways/trustedRootCertificates', applicationGatewayName, 'root-cert')
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
        properties: {
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'public-cert')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendPort')
          }
          protocol: 'Https'
          hostNames: [
            hostName
          ]
          requireServerNameIndication: true
          sslProfile: {
            id: resourceId('Microsoft.Network/applicationGateways/sslProfiles', applicationGatewayName, 'ssl-profile')
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
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
          rewriteRuleSet: {
            id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'client-certificate-rewrite-set')
          }
        }
      }
    ]
    routingRules: []
    probes: [
      {
        name: 'https-probe-01'
        properties: {
          protocol: 'Https'
          host: internalHostName
          port: 443
          path: '/healthz/ready'
          interval: 30
          timeout: 120
          unhealthyThreshold: 8
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {}
        }
      }
    ]
    rewriteRuleSets: [
      {
        name: 'client-certificate-rewrite-set'
        properties: {
          rewriteRules: [
            {
              ruleSequence: 100
              conditions: []
              name: 'x-client-certificate-header'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'x-client-certificate'
                    headerValue: '{var_client_certificate}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
            {
              ruleSequence: 100
              conditions: []
              name: 'x-client-certificate-subject-header'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'x-client-certificate-subject'
                    headerValue: '{var_client_certificate_subject}'
                  }
                ]
                responseHeaderConfigurations: []
              }
            }
          ]
        }
      }
    ]
    redirectConfigurations: []
    privateLinkConfigurations: []
  }
}

output name string = applicationGateway.name
output ipAddress string = publicIPAddress.properties.ipAddress
output vipDnsName string = publicIPAddress.properties.dnsSettings.fqdn
