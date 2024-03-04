param location string
param name string
param subnetId string
param skuName string = 'Standard'
param workspaceName string
param publicIpName string
param firewallSku object = {
  name: 'AZFW_VNet'
  tier: 'Standard'
}

var suffix = uniqueString(resourceGroup().id)
var policyName = 'policy-${suffix}'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource azure_firewall_pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
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

resource azure_firewall_policy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: policyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

resource azure_firewall_rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-07-01' = {
  name: 'rule-collection-01'
  parent: azure_firewall_policy
  properties: {
    priority: 1000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'allow-all'
        priority: 1000
        rules: [
          {
            name: 'allow-all-application-rule'
            ruleType: 'ApplicationRule'
            description: 'allow all outboud to mcr & storage'
            sourceAddresses: [
              '*'
            ]
            targetFqdns: [
              'mcr.microsoft.com'
              '*.mcr.microsoft.com'
              '*.${environment().suffixes.storage}'
            ]
            fqdnTags: [
              'MicrosoftContainerRegistry'
              'AzureFrontDoor.FirstParty'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
              {
                protocolType: 'Http'
                port: 80
              }
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'allow-all-network'
        priority: 1010
        rules: [
          {
            name: 'allow-ntp'
            ruleType: 'NetworkRule'
            description: 'allow all outbound ntp'
            sourceAddresses: [
              '*'
            ]
            destinationAddresses: [
              '*'
            ]
            ipProtocols: [
              'UDP'
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
    ]
  }
}

resource azure_firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: name
  location: location
  properties: {
    sku: firewallSku
    firewallPolicy: {
      id: azure_firewall_policy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig-01'
        properties: {
          publicIPAddress: {
            id: azure_firewall_pip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource firewall_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: azure_firewall
  name: 'azfw-diag'
  properties: {
    workspaceId: workspace.id
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

output ipAddress string = azure_firewall.properties.ipConfigurations[0].properties.privateIPAddress
