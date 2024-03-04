param location string
param vnetIntegrationSubnetId string
param privateEndpointSubnetId string
param logicAppPrivateDNSZoneName string = 'azurewebsites.net'
param vnetId string
param suffix string
param tags object
param minimumElasticSize int = 1

var hostingPlanName = 'ep-${suffix}'
var logicAppName = 'logic-${suffix}'
var appInsightsName = 'ai-${suffix}'
var logicAppStorageAccountName = 'funcstor${suffix}'
var fileShareName = 'myfunctionfiles'

var privateEndpointWebJobsQueueStorageName = 'webjobs-queue-private-endpoint-${suffix}'
var privateEndpointWebJobsTableStorageName = 'webjobs-table-private-endpoint-${suffix}'
var privateEndpointWebJobsBlobStorageName = 'webjobs-blob-private-endpoint-${suffix}'
var privateEndpointWebJobsFileStorageName = 'webjobs-file-private-endpoint-${suffix}'

var privateStorageQueueDnsZoneName = 'privatelink.queue.core.windows.net'
var privateStorageBlobDnsZoneName = 'privatelink.blob.core.windows.net'
var privateStorageTableDnsZoneName = 'privatelink.table.core.windows.net'
var privateStorageFileDnsZoneName = 'privatelink.file.core.windows.net'

resource hostingPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  dependsOn: [
    logicAppStorageAccount
  ]
  name: hostingPlanName
  location: location
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  kind: 'elastic'
  properties: {
    targetWorkerCount: minimumElasticSize
    maximumElasticWorkerCount: 20
    elasticScaleEnabled: true
    isSpot: false
    zoneRedundant: true
  }
}

// App service containing the workflow runtime
resource logicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${listKeys(logicAppStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${listKeys(logicAppStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: fileShareName
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~2'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
      ]
      use32BitWorkerProcess: true
    }
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
  }
}

/* resource funcApp 'Microsoft.Web/sites@2021-01-01' = {
  dependsOn: [
    appInsights
    hostingPlan
    logicAppStorageAccount
  ]
  name: funcAppName
  kind: 'functionapp,linux'
  location: location
  tags: {}
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'custom'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${appInsightsName}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${listKeys(logicAppStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${logicAppStorageAccount.name};AccountKey=${listKeys(logicAppStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: fileShareName
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
      ]
      use32BitWorkerProcess: use32BitWorkerProcess
      linuxFxVersion: linuxFxVersion
    }
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
    clientAffinityEnabled: false
  }
} */

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: appInsightsName
  kind: 'web'
  location: location
  tags: {}
  properties: {
    Application_Type: 'web'
  }
  dependsOn: []
}

resource queueStoragePrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: privateStorageQueueDnsZoneName
}

resource tableStoragePrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: privateStorageTableDnsZoneName
}

resource fileStoragePrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: privateStorageFileDnsZoneName
}

resource blobStoragePrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: privateStorageBlobDnsZoneName
}

resource queueStoragePrivateEndpointDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  location: 'global'
  parent: queueStoragePrivateEndpointDnsZone
  name: '${queueStoragePrivateEndpointDnsZone.name}-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource blobStoragePrivateEndpointDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  location: 'global'
  parent: blobStoragePrivateEndpointDnsZone
  name: '${blobStoragePrivateEndpointDnsZone.name}-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource fileStoragePrivateEndpointDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  location: 'global'
  parent: fileStoragePrivateEndpointDnsZone
  name: '${fileStoragePrivateEndpointDnsZone.name}-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource tableStoragePrivateEndpointDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  location: 'global'
  parent: tableStoragePrivateEndpointDnsZone
  name: '${tableStoragePrivateEndpointDnsZone.name}-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource logicAppStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: logicAppStorageAccountName
  kind: 'StorageV2'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
/*         {
          action: 'Allow'
          id: subnets[0].id
        }
        {
          action: 'Allow'
          id: subnets[1].id
        }
        {
          action: 'Allow'
          id: subnets[2].id
        }
        {
          action: 'Allow'
          id: subnets[3].id
        } */
      ]
      ipRules: []
      defaultAction: 'Deny'
    }
    encryption: {
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-04-01' = {
  parent: logicAppStorageAccount
  name: 'default'
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  parent: fileServices
  name: fileShareName
}

resource queueStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: privateEndpointWebJobsQueueStorageName
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointWebJobsQueueStorageName}-cxn'
        properties: {
          privateLinkServiceId: logicAppStorageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource queueStoragePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: queueStoragePrivateEndpoint
  name: 'queueStoragePrivateENdpointDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: queueStoragePrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

resource tableStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: privateEndpointWebJobsTableStorageName
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointWebJobsTableStorageName}-cxn'
        properties: {
          privateLinkServiceId: logicAppStorageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource tableStoragePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: tableStoragePrivateEndpoint
  name: 'tableStoragePrivateENdpointDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: tableStoragePrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

resource blobStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: privateEndpointWebJobsBlobStorageName
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointWebJobsBlobStorageName}-cxn'
        properties: {
          privateLinkServiceId: logicAppStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource blobStoragePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: blobStoragePrivateEndpoint
  name: 'blobStoragePrivateENdpointDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: blobStoragePrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

resource fileStoragePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  location: location
  name: privateEndpointWebJobsFileStorageName
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointWebJobsFileStorageName}-cxn'
        properties: {
          privateLinkServiceId: logicAppStorageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource fileStoragePrivateEndpointDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: fileStoragePrivateEndpoint
  name: 'fileStoragePrivateENdpointDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: fileStoragePrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

resource logicAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${logicAppName}/VirtualNetwork'
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
  }
}

resource logicAppPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: location
  tags: tags
  name: 'logicAppPrivateEndpoint'
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'logicAppConnection'
        properties: {
          privateLinkServiceId: logicApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource logicAppPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: logicAppPrivateDNSZoneName
  properties: {}
}

resource AppSvcHubVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${logicAppPrivateEndpointDnsZone.name}/${logicAppPrivateEndpointDnsZone.name}-hub-func-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource logicAppPrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${logicAppPrivateEndpoint.name}/funcDnsGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: logicAppPrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

output funcAppUrl string = logicApp.properties.defaultHostName
output funcAppName string = logicApp.name
