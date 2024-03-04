param firewallSubnetRef string
param sourceAddressRangePrefix array
param suffix string
param retentionInDays int = 7
param workspaceId string
param location string

var publicIpName = 'azfw-pip-${suffix}'
var firewallName = 'azfw-${suffix}'

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource azFirewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: firewallName
  location: location
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: firewallSubnetRef
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'aks'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-aks'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*.azmk8s.io'
                '*auth.docker.io'
                '*cloudflare.docker.io'
                '*cloudflare.docker.com'
                '*registry-1.docker.io'
              ]
            }
          ]
        }
      }
      {
        name: 'oss'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-oss'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                'download.opensuse.org'
                'login.microsoftonline.com'
                '*.ubuntu.com'
                'dc.services.visualstudio.com'
                '*.opinsights.azure.com'
                'github.com'
                '*.github.com'
                'raw.githubusercontent.com'
                '*.ubuntu.com'
                'api.snapcraft.io'
                'download.opensuse.org'
              ]
            }
          ]
        }
      }
      {
        name: 'azure'
        properties: {
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-sites'
              sourceAddresses: sourceAddressRangePrefix
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                '*azurecr.io'
                '*blob.${environment().suffixes.storage}'
                '*.trafficmanager.net'
                '*.azureedge.net'
                '*.microsoft.com'
                '*.${environment().suffixes.storage}'
                'aka.ms'
                '*.azure-automation.net'
                '*.azure.com'
              ]
            }
          ]
        }
      }
      {
        name: 'windows-update'
        properties: {
          priority: 400
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-windows-update'
              sourceAddresses: sourceAddressRangePrefix
              fqdnTags: [
                'WindowsUpdate'
              ]
            }
          ]
        }
      }
      {
        name: 'ntp'
        properties: {
          priority: 500
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-ntp'
              sourceAddresses: sourceAddressRangePrefix
              fqdnTags: [
                'Internet'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRulesCollection'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-ssh-https'
              sourceAddresses: sourceAddressRangePrefix
              destinationAddresses: union(sourceAddressRangePrefix, array('*'))
              destinationPorts: [
                '22'
                '443'
              ]
              protocols: [
                'TCP'
              ]
            }
          ]
        }
      }
    ]
  }
}

resource azFirewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'az-fw-diagnostics'
  scope: azFirewall
  properties: {
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
      {
        category: 'AzureFirewallDnsProxy'
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

output firewallPrivateIp string = azFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIp string = publicIP.properties.ipAddress
