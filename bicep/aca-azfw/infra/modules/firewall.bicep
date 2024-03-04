param location string
param suffix string
param firewallSubnetRef string
param sourceAddressRangePrefixes array
param workspaceRef string

var publicIpName = 'fw-pip-${suffix}'
var firewallName = 'fw-${suffix}'
//var sourceAddresses = [for item in sourceAddressRangePrefixes: item.properties.addressPrefixes]

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-03-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
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
    natRuleCollections: [

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
              sourceAddresses: sourceAddressRangePrefixes
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
              fqdnTags: [
                'AzureKubernetesService'
              ]
            }
          ]
        }
      }
      {
        name: 'azure'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-azure-services'
              sourceAddresses: sourceAddressRangePrefixes
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
                'dc.services.visualstudio.com'
                '*.opinsights.azure.com'
                'login.microsoftonline.com'
                '*azurecr.io'
                '*.blob.core.windows.net'
                '*.trafficmanager.net'
                '*.azureedge.net'
                '*.microsoft.com'
                '*.core.windows.net'
                'aka.ms'
                '*.azure-automation.net'
                '*.azure.com'
                'gov-prod-policy-data.trafficmanager.net'
                '*.gk.${location}.azmk8s.io'
                '*.monitoring.azure.com'
                '*.oms.opinsights.azure.com'
                '*.ods.opinsights.azure.com'
                '*.microsoftonline.com'
                '*.data.mcr.microsoft.com'
                '*.cdn.mscr.io'
                'mcr.microsoft.com'
                'management.azure.com'
                'packages.microsoft.com'
                '*.dp.kubernetesconfiguration.azure.com'
                'azurearcfork8s.azurecr.io'
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
              name: 'allow-internal'
              sourceAddresses: sourceAddressRangePrefixes
              destinationAddresses: sourceAddressRangePrefixes
              destinationPorts: [
                '*'
              ]
              protocols: [
                'Any'
              ]
            }
          ]
        }
      }
      {
        name: 'aca-rules'
        properties: {
          action: {
            type: 'Allow'
          }
          priority: 200
          rules: [
            {
              name: 'apiudp'
              protocols: [
                'UDP'
              ]
              destinationAddresses: [
                'AzureCloud.${location}'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationPorts: [
                '1194'
              ]
            }
            {
              name: 'apitcp'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                'AzureCloud.${location}'
              ]
              destinationPorts: [
                '9000'
              ]
            }
            {
              name: 'ntp'
              protocols: [
                'UDP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '123'
              ]
            }
            {
              name: 'control-plane'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '5671'
                '5672'
              ]
            }
            {
              name: 'http'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '80'
              ]
            }
            {
              name: 'https'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '443'
              ]
            }
          ]
        }
      }
      /* {
        name: 'netRulesCollection'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'allow-outbound-http-https-internet'
              sourceAddresses: sourceAddresses
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '80'
                '443'
                '53'
                '123'
                '22'
              ]
              protocols: [
                'TCP'
                'UDP'
                'ICMP'
              ]
            }
          ]
        }
      } */
    ]
  }
}

resource firewall_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: firewall
  name: 'fwdiagnostics'
  properties: {
    workspaceId: workspaceRef
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output firewallPublicIpAddress string = publicIP.properties.ipAddress
