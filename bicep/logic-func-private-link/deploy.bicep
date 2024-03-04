param location string
param adminUserName string = 'azureuser'
param sshKeyData string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809'

var affix = uniqueString(resourceGroup().id)
var wksName = 'wks-${affix}'
var funcAppName = 'func-${affix}'
var logicAppName = 'logic-${affix}'
var vmNsgName = 'linux-vm-1-nsg'
var vmPipName = 'linux-vm-1-ip'
var vnetName = 'logic-func-vnet'
var logicStorageAccount = 'logicfunctestrgad01'
var logicStorageAccount2 = 'logicfunctestrgaf02'
var logicStorageAccount3 = 'logicfunctestrgb9b2'
var logicAsp = 'logic-asp-${affix}'

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: wksName
  location: location
}

resource cbellee_func_1 'Microsoft.Insights/components@2020-02-02' = {
  name: funcAppName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaWebAppExtensionCreate'
    RetentionInDays: 90
    WorkspaceResourceId: wks.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource cbellee_logic_1 'microsoft.insights/components@2020-02-02' = {
  name: logicAppName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaWebAppExtensionCreate'
    RetentionInDays: 90
    WorkspaceResourceId: wks.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource linux_vm_1_nsg 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: vmNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource privatelink_azurewebsites_net 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.azurewebsites.net'
  location: 'global'
}

resource linux_vm_1_ip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: vmPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
  ]
}

resource logic_func_vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: 'private-endpoint-subnet'
        properties: {
          addressPrefixes: [
            '10.0.2.0/24'
          ]
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'func-integration-subnet'
        properties: {
          addressPrefixes: [
            '10.0.0.0/24'
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'australiaeast'
                'australiasoutheast'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'logic-integration-subnet'
        properties: {
          addressPrefixes: [
            '10.0.1.0/24'
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'australiaeast'
                'australiasoutheast'
              ]
            }
          ]
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'mgmt-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.4.0/24'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource logicfunctestrgad12 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: logicStorageAccount
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
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

resource logicfunctestrgaf02 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: logicStorageAccount2
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
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

resource logicfunctestrgb9b2 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: logicStorageAccount3
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: true
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
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

resource ASP_logicfunctestrg_a8dc 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: logicAsp
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
    size: 'WS1'
    family: 'WS'
    capacity: 1
  }
  kind: 'elastic'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 20
    isSpot: false
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource linux_vm_1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'linux-vm-1'
  location: location
  tags: {
    autostart: 'true'
    autostop: 'true'
  }
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        // name: 'linux-vm-1_OsDisk_1_acf34db3b26a4e6c92b9d566e6dd3809'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        /* managedDisk: {
          id: resourceId('Microsoft.Compute/disks', 'linux-vm-1_OsDisk_1_acf34db3b26a4e6c92b9d566e6dd3809')
        } */
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: 'linux-vm-1'
      adminUsername: adminUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: sshKeyData
            }
          ]
        }
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource linux_vm_1_nsg_SSH 'Microsoft.Network/networkSecurityGroups/securityRules@2023-06-01' = {
  name: 'SSH'
  parent: linux_vm_1_nsg
  properties: {
    protocol: 'TCP'
    sourcePortRange: '*'
    destinationPortRange: '22'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 300
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource privatelink_azurewebsites_net_cbellee_func_1 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: funcAppName
  properties: {
    metadata: {
      creator: 'created by private endpoint func-pe with resource guid 16c43090-da69-4f63-b32e-5a137d27b99a'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.2.4'
      }
    ]
  }
}

resource privatelink_azurewebsites_net_cbellee_func_1_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: '${funcAppName}.scm'
  properties: {
    metadata: {
      creator: 'created by private endpoint func-pe with resource guid 16c43090-da69-4f63-b32e-5a137d27b99a'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.2.4'
      }
    ]
  }
}

resource privatelink_azurewebsites_net_cbellee_logic_1 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: logicAppName
  properties: {
    metadata: {
      creator: 'created by private endpoint logic-pe with resource guid 81890054-d23a-4e69-8fcf-65dc50b93223'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.2.5'
      }
    ]
  }
}

resource privatelink_azurewebsites_net_cbellee_logic_1_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: '${logicAppName}.scm'
  properties: {
    metadata: {
      creator: 'created by private endpoint logic-pe with resource guid 81890054-d23a-4e69-8fcf-65dc50b93223'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '10.0.2.5'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA_privatelink_azurewebsites_net 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

/* resource logic_func_vnet_AzureBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'AzureBastionSubnet'
  parent: logic_func_vnet
  properties: {
    addressPrefix: '10.0.4.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
} */

resource logic_func_vnet_func_integration_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'func-integration-subnet'
  parent: logic_func_vnet
  properties: {
    addressPrefixes: [
      '10.0.0.0/24'
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          'australiaeast'
          'australiasoutheast'
        ]
      }
    ]
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource logic_func_vnet_logic_integration_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'logic-integration-subnet'
  parent: logic_func_vnet
  properties: {
    addressPrefixes: [
      '10.0.1.0/24'
    ]
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          'australiaeast'
          'australiasoutheast'
        ]
      }
    ]
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource logic_func_vnet_mgmt_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'mgmt-subnet'
  parent: logic_func_vnet
  properties: {
    addressPrefix: '10.0.3.0/24'
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource logic_func_vnet_private_endpoint_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'private-endpoint-subnet'
  parent: logic_func_vnet
  properties: {
    addressPrefixes: [
      '10.0.2.0/24'
    ]
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource logicfunctestrgad12_default 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: logicfunctestrgad12
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource logicfunctestrgaf02_default 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: logicfunctestrgaf02
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource logicfunctestrgb9b2_default 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: logicfunctestrgb9b2
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource Microsoft_Storage_storageAccounts_fileServices_logicfunctestrgad12_default 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: logicfunctestrgad12
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
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

resource Microsoft_Storage_storageAccounts_fileServices_logicfunctestrgaf02_default 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: logicfunctestrgaf02
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
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

resource Microsoft_Storage_storageAccounts_fileServices_logicfunctestrgb9b2_default 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  parent: logicfunctestrgb9b2
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
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

resource Microsoft_Storage_storageAccounts_queueServices_logicfunctestrgad12_default 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  parent: logicfunctestrgad12
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_logicfunctestrgaf02_default 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  parent: logicfunctestrgaf02
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_queueServices_logicfunctestrgb9b2_default 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  parent: logicfunctestrgb9b2
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_logicfunctestrgad12_default 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: logicfunctestrgad12
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_logicfunctestrgaf02_default 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: logicfunctestrgaf02
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Storage_storageAccounts_tableServices_logicfunctestrgb9b2_default 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: logicfunctestrgb9b2
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource Microsoft_Web_sites_cbellee_func_1 'Microsoft.Web/sites@2023-01-01' = {
  name: funcAppName
  location: location
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/logic-func-test-rg/providers/microsoft.insights/components/cbellee-func-1'
    'hidden-link: /app-insights-instrumentation-key': 'd8aa13dd-6b8e-4b3b-8b37-5a8b36a70caa'
    'hidden-link: /app-insights-conn-string': 'InstrumentationKey=d8aa13dd-6b8e-4b3b-8b37-5a8b36a70caa;IngestionEndpoint=https://australiaeast-1.in.applicationinsights.azure.com/;LiveEndpoint=https://australiaeast.livediagnostics.monitor.azure.com/'
  }
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'cbellee-func-1.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'cbellee-func-1.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    //serverFarmId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/auror-demo-rg/providers/Microsoft.Web/serverfarms/asp-get5w7drjasp4'
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'PowerShell|7.2'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: 'FFD4FAA64008FB3A18609464ED0F234F42089CF1DBA43D7BDCB2BD3F95B6F429'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    publicNetworkAccess: 'Disabled'
    storageAccountRequired: false
    virtualNetworkSubnetId: logic_func_vnet_func_integration_subnet.id
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource cbellee_func_1_web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_func_1
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v4.0'
    linuxFxVersion: 'PowerShell|7.2'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$cbellee-func-1'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetName: 'cacd8958-568e-48d4-8d8e-d25a9cbfa662_func-integration-subnet'
    vnetRouteAllEnabled: true
    vnetPrivatePortsCount: 0
    publicNetworkAccess: 'Disabled'
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 1
    functionAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: false
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
  }
}

resource cbellee_logic_1_web 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_logic_1
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
    ]
    netFrameworkVersion: 'v6.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    acrUseManagedIdentityCreds: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$cbellee-logic-1'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: false
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    vnetName: 'cacd8958-568e-48d4-8d8e-d25a9cbfa662_logic-integration-subnet'
    vnetRouteAllEnabled: true
    vnetPrivatePortsCount: 2
    publicNetworkAccess: 'Enabled'
    cors: {
      supportCredentials: false
    }
    localMySqlEnabled: false
    managedServiceIdentityId: 27375
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    ipSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsDefaultAction: 'Allow'
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 1
    functionAppScaleLimit: 0
    functionsRuntimeScaleMonitoringEnabled: true
    minimumElasticInstanceCount: 1
    azureStorageAccounts: {}
  }
}

resource cbellee_func_1_HttpTrigger1 'Microsoft.Web/sites/functions@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_func_1
  name: 'HttpTrigger1'
  properties: {
    script_root_path_href: 'https://cbellee-func-1.azurewebsites.net/admin/vfs/home/site/wwwroot/HttpTrigger1/'
    script_href: 'https://cbellee-func-1.azurewebsites.net/admin/vfs/home/site/wwwroot/HttpTrigger1/run.ps1'
    config_href: 'https://cbellee-func-1.azurewebsites.net/admin/vfs/home/site/wwwroot/HttpTrigger1/function.json'
    test_data_href: 'https://cbellee-func-1.azurewebsites.net/admin/vfs/home/data/Functions/sampledata/HttpTrigger1.dat'
    href: 'https://cbellee-func-1.azurewebsites.net/admin/functions/HttpTrigger1'
    config: {}
    test_data: '{"method":"post","queryStringParams":[],"headers":[],"body":"{\\"name\\":\\"Azure\\"}"}'
    invoke_url_template: 'https://cbellee-func-1.azurewebsites.net/api/httptrigger1'
    language: 'powershell'
    isDisabled: false
  }
}

resource cbellee_func_1_cbellee_func_1_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_func_1
  name: 'cbellee-func-1.azurewebsites.net'
  properties: {
    siteName: funcAppName
    hostNameType: 'Verified'
  }
}

resource cbellee_logic_1_cbellee_logic_1_azurewebsites_net 'Microsoft.Web/sites/hostNameBindings@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_logic_1
  name: 'cbellee-logic-1.azurewebsites.net'
  properties: {
    siteName: logicAppName
    hostNameType: 'Verified'
  }
}

resource cbellee_func_1_func_pe_9d10c69d_a240_4dda_bef9_5842da88a70d 'Microsoft.Web/sites/privateEndpointConnections@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_func_1
  name: 'func-pe-9d10c69d-a240-4dda-bef9-5842da88a70d'
  properties: {
    privateLinkServiceConnectionState: {
      status: 'Approved'
      actionsRequired: 'None'
    }
  }
}

resource cbellee_logic_1_logic_pe_fc1a51ec_2140_4e61_9b51_26ce54cc989d 'Microsoft.Web/sites/privateEndpointConnections@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_logic_1
  name: 'logic-pe-fc1a51ec-2140-4e61-9b51-26ce54cc989d'
  properties: {
    privateLinkServiceConnectionState: {
      status: 'Approved'
      actionsRequired: 'None'
    }
  }
}

resource privatelink_azurewebsites_net_cbellee_func_1_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privatelink_azurewebsites_net
  name: 'cbellee-func-1-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: logic_func_vnet.id
    }
  }
}

resource func_pe 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: 'func-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'func-pe'
        properties: {
          privateLinkServiceId: Microsoft_Web_sites_cbellee_func_1.id
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: logic_func_vnet_private_endpoint_subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource logic_pe 'Microsoft.Network/privateEndpoints@2023-06-01' = {
  name: 'logic-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'logic-pe'
        properties: {
          privateLinkServiceId: Microsoft_Web_sites_cbellee_logic_1.id
          groupIds: [
            'sites'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: logic_func_vnet_private_endpoint_subnet.id
    }
    ipConfigurations: []
    customDnsConfigs: []
  }
}

resource func_pe_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: 'default'
  parent: func_pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurewebsites.net-config'
        properties: {
          privateDnsZoneId: privatelink_azurewebsites_net.id
        }
      }
    ]
  }
}

resource logic_pe_default 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  name: 'default'
  parent: logic_pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurewebsites.net-config'
        properties: {
          privateDnsZoneId: privatelink_azurewebsites_net.id
        }
      }
    ]
  }
}

resource Microsoft_Web_sites_cbellee_logic_1 'Microsoft.Web/sites@2023-01-01' = {
  name: logicAppName
  location: location
  tags: {
    'hidden-link: /app-insights-resource-id': '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/logic-func-test-rg/providers/Microsoft.Insights/components/cbellee-logic-1'
  }
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: 'cbellee-logic-1.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'cbellee-logic-1.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: ASP_logicfunctestrg_a8dc.id
    reserved: false
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: true
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 0
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    customDomainVerificationId: 'FFD4FAA64008FB3A18609464ED0F234F42089CF1DBA43D7BDCB2BD3F95B6F429'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    virtualNetworkSubnetId: logic_func_vnet_logic_integration_subnet.id
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource cbellee_func_1_cacd8958_568e_48d4_8d8e_d25a9cbfa662_func_integration_subnet 'Microsoft.Web/sites/virtualNetworkConnections@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_func_1
  name: 'cacd8958-568e-48d4-8d8e-d25a9cbfa662_func-integration-subnet'
  properties: {
    vnetResourceId: logic_func_vnet_func_integration_subnet.id
    isSwift: true
  }
}

resource cbellee_logic_1_cacd8958_568e_48d4_8d8e_d25a9cbfa662_logic_integration_subnet 'Microsoft.Web/sites/virtualNetworkConnections@2023-01-01' = {
  parent: Microsoft_Web_sites_cbellee_logic_1
  name: 'cacd8958-568e-48d4-8d8e-d25a9cbfa662_logic-integration-subnet'
  properties: {
    vnetResourceId: logic_func_vnet_logic_integration_subnet.id
    isSwift: true
  }
}

resource linux_vm_1676_z1 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: 'linux-vm-1676_z1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          privateIPAddress: '10.0.3.4'
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: linux_vm_1_ip.id
            properties: {
              deleteOption: 'Detach'
            }
          }
          subnet: {
            id: logic_func_vnet_mgmt_subnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: linux_vm_1_nsg.id
    }
    nicType: 'Standard'
    auxiliaryMode: 'None'
    auxiliarySku: 'None'
  }
}
