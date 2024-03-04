param location string
param vnetIntegrationSubnetId string
param privateEndpointSubnetId string
param appSvcPrivateDNSZoneName string = 'azurewebsites.net'
param hubVnetId string
param spokeVnetId string
param suffix string
param use32BitWorkerProcess bool = false
param linuxFxVersion string = ''
param sku string = 'ElasticPremium'
param skuCode string = 'EP1'
param tags object

var hostingPlanName = 'ep-${suffix}'
var funcAppName = 'func-app-${suffix}'
var appInsightsName = 'app-insights-${suffix}'
var storageAccountName = 'funcstor${suffix}'


resource hostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: skuCode
    tier: sku
  }
  kind: 'elastic'
  properties: {
    reserved: true
    maximumElasticWorkerCount: 20
  }
}

resource funcApp 'Microsoft.Web/sites@2021-01-01' = {
  name: funcAppName
  kind: 'functionapp,linux'
  location: location
  tags: {}
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
/*         {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'custom'
        } */
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${appInsightsName}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: reference('microsoft.insights/components/${appInsightsName}', '2015-05-01').ConnectionString
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccount.id, '2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${toLower(funcAppName)}98ad'
        }
      ]
      use32BitWorkerProcess: use32BitWorkerProcess
      linuxFxVersion: linuxFxVersion
    }
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName}'
    clientAffinityEnabled: false
  }
  dependsOn: [
    appInsights
    hostingPlan
  ]
}

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

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: location
  tags: {}
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}


resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${funcApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
  }
}

resource appSvcPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: location
  tags: tags
  name: 'appSvcPrivateEndpoint'
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'funcAppConnection'
        properties: {
          privateLinkServiceId: funcApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource appSvcPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: appSvcPrivateDNSZoneName
  properties: {}
}

resource AppSvcHubVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-hub-func-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

resource AppSvcApokeVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-spoke-func-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

resource appSvcPrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${appSvcPrivateEndpoint.name}/funcDnsGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appSvcPrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

output funcAppUrl string = funcApp.properties.defaultHostName
output funcAppName string = funcApp.name
output PrincipaId string = funcApp.identity.principalId
