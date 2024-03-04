@description('location to deploy the storage account')
param location string
param firewallName string
param sourceAddresses array
param firewallPublicIpName string
param firewallSubnetRef string
param workspaceId string

var sourceAddressPrefixes = [for item in sourceAddresses: item.properties.addressPrefix]

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: firewallPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
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
              sourceAddresses: sourceAddressPrefixes
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
              sourceAddresses: sourceAddressPrefixes
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
                '*.ubuntu.com'
                'github.com'
                'gcr.io'
                '*.github.com'
                'raw.githubusercontent.com'
                '*.ubuntu.com'
                'api.snapcraft.io'
                'download.opensuse.org'
                'storage.googleapis.com'
                'security.ubuntu.com'
                'azure.archive.ubuntu.com'
                'changelogs.ubuntu.com'
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
              sourceAddresses: sourceAddressPrefixes
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
              name: 'allow-outbound-http-https-internet'
              sourceAddresses: sourceAddressPrefixes
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
      }
    ]
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
  }
}

resource firewall_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'firewall-diagnostics'
  scope: firewall
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
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

output firewallName string = firewall.name
output firewallPublicIpAddress string = publicIP.properties.ipAddress
