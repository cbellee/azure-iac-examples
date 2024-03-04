param accountName string = 'stor${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param appName string = 'my-app-cbellee'

@allowed([
  'Dev'
  'Test'
  'Prod'
])
param environmentName string = 'Dev'

var storageAccountSku = (environmentName == 'Prod') ? 'Premium_LRS' : 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: accountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  params: {
    appName: appName
    location: location
  }
}

output appHostName string = appService.outputs.appServiceHostName
