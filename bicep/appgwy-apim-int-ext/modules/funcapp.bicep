param location string
param vnetIntegrationSubnetId string
param suffix string
param use32BitWorkerProcess bool = false
param linuxFxVersion string = ''
param tags object
param planSkuCode string = 'EP1'
param planSku string = 'ElasticPremium'
param planKind string = 'elastic'
param appId string
param apimManagedIdentityPrincipalId string
param apimSubnetId string
param secretUri string

var hostingPlanName = 'ep-${suffix}'
var funcAppName = 'func-${suffix}'
var appInsightsName = 'app-insights-${suffix}'
var funcStorageAccountName = 'funcstor1${suffix}'
var fileShareName = 'myfunctionfiles'
var issuer = 'https://sts.windows.net/${subscription().tenantId}' //'https://login.microsoftonline.com/${subscription().tenantId}/v2.0'

resource hostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  dependsOn: [
    funcStorageAccount
  ]
  name: hostingPlanName
  location: location
  kind: planKind
  sku: {
    name: planSkuCode
    tier: planSku
  }
  properties: {
    reserved: true
    maximumElasticWorkerCount: 20
  }
}

resource funcApp 'Microsoft.Web/sites@2021-01-01' = {
  dependsOn: [
    appInsights
    hostingPlan
  ]
  name: funcAppName
  kind: 'functionapp,linux,container'
  location: location
  identity: {
     type: 'SystemAssigned'
  }
  tags: {}
  properties: {
    ipSecurityRestrictions: [
      {
          vnetSubnetResourceId: apimSubnetId
          action: 'Allow'
          tag: 'Default'
          priority: 100
          name: 'allow-apim-inbound'
          description: 'allow-apim-inbound'
      }
  ]
  scmIpSecurityRestrictionsUseMain: true
    siteConfig: {
      appSettings: [
        {
          name: 'DB_CXN'
          value: '@Microsoft.KeyVault(SecretUri=${secretUri})'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference('microsoft.insights/components/${appInsightsName}', '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccount.name};AccountKey=${listKeys(funcStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${funcStorageAccount.name};AccountKey=${listKeys(funcStorageAccount.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '0'
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
}

resource funcAppAuthSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: funcApp
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: true
      unauthenticatedClientAction: 'Return401'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          openIdIssuer: issuer
          clientId: appId
          clientSecretSettingName: 'AD_IDENTITY_CLIENT_SECRET'
        }
        validation: {
          allowedAudiences: [
            apimManagedIdentityPrincipalId
          ]
        }
        isAutoProvisioned: false
      }
      login: {
        tokenStore: {
          enabled: true
        }
      }
    }
  }
}

/* resource funcAppAuthSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: funcApp
  name: 'authsettingsV2'
  properties: {
    platform: {
      properties: {
        enabled: true
      }
    }
    globalValidation: {
      properties: {
        requireAuthentication: true
        unauthenticatedClientAction: 'Return401'
        redirectToProvider: 'azureActiveDirectory'
      }
    }
    identityProviders: {
      properties: {
        azureActiveDirectory: {
          properties: {
            enabled: true
            isAutoProvisioned: true
            registration: {
              properties: {
                clientId: appId
                openIdIssuer: issuer
              }
            }
            validation: {
              properties: {
                allowedAudiences: [
                  apimManagedIdentityPrincipalId
                ]
              }
            }
          }
        }
      }
    }
    login: {
      properties: {
        tokenStore: {
          properties: {
            enabled: true
            tokenRefreshExtensionHours: 72
          }
        }
      }
    } */

/* enabled: true
    unauthenticatedClientAction: 'RedirectToLoginPage'
    tokenStoreEnabled: true
    defaultProvider: 'AzureActiveDirectory'
    tokenRefreshExtensionHours: 72 // default value is 72 hours
    clientId: appId
    issuer: issuer
    validateIssuer: true
    allowedAudiences: [
      apimManagedIdentityPrincipalId
    ] 
  }
}
    */

/* resource funcAppAuthSettings 'Microsoft.Web/sites/config@2021-01-15' = {
  parent: funcApp
  name: 'authsettings'
  properties: {
    enabled: true
    unauthenticatedClientAction: 'RedirectToLoginPage'
    tokenStoreEnabled: true
    defaultProvider: 'AzureActiveDirectory'
    tokenRefreshExtensionHours: 72 // default value is 72 hours
    clientId: appId
    issuer: issuer
    validateIssuer: true
    allowedAudiences: [
      apimManagedIdentityPrincipalId
    ]
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

resource funcStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: funcStorageAccountName
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
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
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
  parent: funcStorageAccount
  name: 'default'
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  parent: fileServices
  name: fileShareName
}

resource funcAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${funcApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
  }
}

output funcAppUrl string = 'https://${funcApp.properties.defaultHostName}'
output funcAppName string = funcApp.name
output principalId string = funcApp.identity.principalId
