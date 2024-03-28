param location string = 'australiaeast'
param virtualNetworkName string
param aiName string
param appServicePlanName string
param storageAccount1Name string
param storageAccount2Name string
param subnetName string
param uamiName string
param queueName string

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

var suffix = uniqueString(resourceGroup().id)
var logicAppName = 'logic-app-${suffix}-${environment}'
var storageAccountBlobContributorRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageAccountQueueContributorRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/974c5e8b-45b9-4653-ba55-5f855dd0fb88'

resource storageAccount1 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccount1Name
}

resource storageAccount2 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccount2Name
}

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  location: location
}

resource ai 'Microsoft.Insights/components@2020-02-02' existing = {
  name: aiName
}

module logicApp './modules/logicApp.bicep' = {
  name: 'logicApp'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    appServicePlanName: appServicePlanName
    subnetName: subnetName
    uamiName: uamiName
    logicAppName: logicAppName
  }
}

resource storageAccountBlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'storageAccountBlobRoleAssignment', storageAccount1Name)
  scope: storageAccount1
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: storageAccountBlobContributorRole
  }
}
resource storageAccountQueueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'storageAccountQueueRoleAssignment', storageAccount1Name)
  scope: storageAccount1
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: storageAccountQueueContributorRole
  }
}

resource storageAccount2BlobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'storageAccountBlobRoleAssignment', storageAccount2Name)
  scope: storageAccount2
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: storageAccountBlobContributorRole
  }
}
resource storageAccount2QueueContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, 'storageAccountQueueRoleAssignment', storageAccount2Name)
  scope: storageAccount2
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: storageAccountQueueContributorRole
  }
}

module apiConnections 'modules/apiConnections.bicep' = {
  name: 'apiConnection'
  params: {
    location: location
    uamiName: uamiName
    storageAccountName: storageAccount2Name
  }
  dependsOn: [
    logicApp
  ]
}

module appSettings 'modules/logicAppSettings.bicep' = {
  name: 'appSettings'
  params: {
    webAppName: logicApp.outputs.name
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', logicAppName, 'appsettings'), '2023-01-01').properties
    appSettings: {
      APP_KIND: 'workflowApp'
      APPINSIGHTS_INSTRUMENTATIONKEY: ai.properties.InstrumentationKey
      APPLICATIONINSIGHTS_CONNECTION_STRING: ai.properties.ConnectionString
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount1.name};AccountKey=${listKeys(storageAccount1.id, storageAccount1.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
      WEBSITE_CONTENTSHARE: 'app-${toLower(logicApp.name)}-logicservice-${toLower(environment)}a6e9'
      WEBSITE_NODE_DEFAULT_VERSION: '~18'
      AzureFunctionsJobHost__extensionBundle__id: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
      AzureFunctionsJobHost__extensionBundle__version: '[1.*, 2.0.0)'
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'node'
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount1.name};AccountKey=${listKeys(storageAccount1.id, storageAccount1.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
      workflow_subscription_id: subscription().subscriptionId
      workflow_location: location
      workflow_rg_name: resourceGroup().name
      azurequeues_connection_string: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount2.name};AccountKey=${listKeys(storageAccount2.id, storageAccount2.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
      queue_name: queueName
      azureblob_connection_runtime_url: apiConnections.outputs.blobConnectionRuntimeUrl
      api_connection_name: apiConnections.outputs.azureBlobApiConnectionName
    }
  }
  dependsOn: [
    apiConnections
  ]
}

output logicAppName string = logicApp.outputs.name
