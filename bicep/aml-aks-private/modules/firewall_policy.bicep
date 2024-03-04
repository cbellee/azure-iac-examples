param location string
param sourceAddresses array
param firewallName string

var sourceAddressPrefixes = [for item in sourceAddresses: item.properties.addressPrefix]

resource fw 'Microsoft.Network/azureFirewalls@2021-05-01' existing = {
  name: firewallName
}

// create a new firewall policy
resource fw_policy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
  name: 'fw-policy-1'
  location: location
}

// add application & network rules to the policy
resource fw_policy_rule_collection_group 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-04-01' = {
  name: 'rule-collection-group-1'
  parent: fw_policy
  properties: {
    priority: 1000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'network-rules'
        priority: 1100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow-outbound-internnet'
            sourceAddresses: sourceAddressPrefixes
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '443'
              '80'
              '53'
              '123'
              '1688'
            ]
            ipProtocols: [
              'TCP'
              'UDP'
            ]
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'application-rules'
        priority: 1200
        rules: [
          {
            name: 'allow-aks-outbound'
            ruleType: 'ApplicationRule'
            sourceAddresses: sourceAddressPrefixes
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              'mcr.microsoft.com'
              '*.data.mcr.microsoft.com'
            ]
            fqdnTags: [
              'AzureKubernetesService'
            ]
          }
        ]
      }
    ]
  }
}
