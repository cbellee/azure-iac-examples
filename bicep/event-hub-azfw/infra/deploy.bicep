param location string

var affix = uniqueString(resourceGroup().id)

resource ev_hub_fw_policy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: 'ev-hub-fw-policy-${affix}'
  location: location
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    intrusionDetection: {
      mode: 'Off'
    }
  }
}

resource privatelink_servicebus_windows_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.servicebus.windows.net'
  location: 'global'
}

resource ev_hub_fw_pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: 'ev-hub-fw-pip-${affix}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '20.213.87.225'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-${affix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'PrivateEndpointSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource stor 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'stor${affix}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource eh_namespace 'Microsoft.EventHub/namespaces@2022-01-01-preview' = {
  name: 'namespace-${affix}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: false
    zoneRedundant: true
    privateEndpointConnections: [
      {
        properties: {
          privateEndpoint: {
            id: ev_hub_fw_pe.id
          }
        }
      }
    ]
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

resource eh_namespace_default 'Microsoft.EventHub/namespaces/networkRuleSets@2022-01-01-preview' = {
  name: 'cbellee-namespace-1/default'
  properties: {
    publicNetworkAccess: 'Disabled'
    defaultAction: 'Allow'
    virtualNetworkRules: []
    ipRules: []
  }
}

resource ev_hub_fw_policy_DefaultDnatRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: ev_hub_fw_policy
  name: 'DefaultDnatRuleCollectionGroup'
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'Dnat'
        }
        rules: [
          {
            ruleType: 'NatRule'
            name: 'event-hub-dnat-rule-1'
            translatedAddress: '10.0.2.4'
            translatedPort: '5671'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '20.213.87.225'
            ]
            destinationPorts: [
              '5671'
            ]
          }
          {
            ruleType: 'NatRule'
            name: 'event-hub-dnat-rule-2'
            translatedAddress: '10.0.2.4'
            translatedPort: '5672'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '20.213.87.225'
            ]
            destinationPorts: [
              '5672'
            ]
          }
          {
            ruleType: 'NatRule'
            name: 'event-hub-dnat-rule-3'
            translatedAddress: '10.0.2.4'
            translatedPort: '443'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '20.213.87.225'
            ]
            destinationPorts: [
              '443'
            ]
          }
        ]
        name: 'event-hub-dnat'
        priority: 1000
      }
    ]
  }
}

resource ev_hub_fw_policy_DefaultNetworkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: ev_hub_fw_policy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'allow_all_private'
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '10.0.0.0/8'
            ]
            sourceIpGroups: []
            destinationAddresses: [
              '10.0.0.0/8'
            ]
            destinationIpGroups: []
            destinationFqdns: []
            destinationPorts: [
              '*'
            ]
          }
        ]
        name: 'allow_all_peivate'
        priority: 1000
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'win-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'privateEndpointIpConfig.276b0bcb-d14a-4553-81b2-d35d8cba8583'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet_PrivateEndpointSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource stor_default 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: stor
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

resource stor_file_services 'Microsoft.Storage/storageAccounts/fileServices@2021-09-01' = {
  parent: stor
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
      }
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource stor_queue_services 'Microsoft.Storage/storageAccounts/queueServices@2021-09-01' = {
  parent: stor
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource stor_table_services 'Microsoft.Storage/storageAccounts/tableServices@2021-09-01' = {
  parent: stor
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource eh_namespace_evhub 'Microsoft.EventHub/namespaces/eventhubs@2022-01-01-preview' = {
  name: '${eh_namespace.name}/ehcbellee1'
  parent: eh_namespace
  location: location
  properties: {
    messageRetentionInDays: 1
    partitionCount: 1
    status: 'Active'
    captureDescription: {
      enabled: true
      encoding: 'Avro'
      destination: {
        name: 'EventHubArchive.AzureBlockBlob'
        properties: {
          storageAccountResourceId: stor.id
          blobContainer: 'evhubcontainer1'
          archiveNameFormat: '{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}'
        }
      }
      intervalInSeconds: 300
      sizeLimitInBytes: 314572800
    }
  }
}

resource eh_namespace_ehcbellee1_send_listen_policy 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2022-01-01-preview' = {
  parent: eh_namespace_ehcbellee1
  name: 'send_listen_policy'
  location: location
  properties: {
    rights: [
      'Listen'
      'Send'
    ]
  }
  dependsOn: [
    eh_namespace
  ]
}

resource eh_namespace_ehcbellee1_Default 'Microsoft.EventHub/namespaces/eventhubs/consumergroups@2022-01-01-preview' = {
  parent: eh_namespace_ehcbellee1
  name: '$Default'
  location: location
  properties: {
  }
}

resource eh_namespace_0d4dd2d6_aa85_46a0_a5a3_0ab58d8cc2cd 'Microsoft.EventHub/namespaces/privateEndpointConnections@2022-01-01-preview' = {
  name: 'cbellee-namespace-1/0d4dd2d6-aa85-46a0-a5a3-0ab58d8cc2cd'
  location: location
  properties: {
    provisioningState: 'Succeeded'
    privateEndpoint: {
      id: ev_hub_fw_pe.id
    }
    privateLinkServiceConnectionState: {
      status: 'Approved'
      description: 'Auto-Approved'
    }
  }
}

resource privatelink_servicebus_windows_net_qzcithsmtylck 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_servicebus_windows_net
  name: 'qzcithsmtylck'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource ev_hub_fw_pe 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: 'ev-hub-fw-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'ev-hub-fw-pe_35efd664-8864-4e9a-be63-51160c8b904e'
        properties: {
          privateLinkServiceId: eh_namespace.id
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: vnet_PrivateEndpointSubnet.id
    }
    customDnsConfigs: [
      {
        fqdn: 'cbellee-namespace-1.servicebus.windows.net'
        ipAddresses: [
          '10.0.2.4'
        ]
      }
    ]
  }
}

resource stor_default_evhubcontainer1 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  parent: stor_default
  name: 'evhubcontainer1'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
  dependsOn: [
    stor
  ]
}

resource ev_hub_fw_azfw 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  name: 'ev-hub-fw-azfw'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    additionalProperties: {
    }
    ipConfigurations: [
      {
        name: 'ev-hub-fw-pip'
        properties: {
          publicIPAddress: {
            id: ev_hub_fw_pip.id
          }
          subnet: {
            id: vnet_AzureFirewallSubnet.id
          }
        }
      }
    ]
    networkRuleCollections: []
    applicationRuleCollections: []
    natRuleCollections: []
    firewallPolicy: {
      id: ev_hub_fw_policy.id
    }
  }
}
