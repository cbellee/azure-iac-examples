param location string
param addressPrefix string
param autoscaleMaxThroughput int = 1000

@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

var suffix = uniqueString(resourceGroup().id)
var vnetName = 'vnet-${suffix}'
var keyVaultName = 'kv-${suffix}'
var appServicePlanName = 'asp-${suffix}'
var cosmosAccountName = 'cosmos-account-${suffix}'
var databaseName = 'test-db'
var containerName = 'default'
var uamiName = 'umid-${suffix}'
var keyVaultSecretsUserRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'
var storageAccount1Name = 'sa1${suffix}'
var storageAccount2Name = 'sa2${suffix}'
var storageAccount1QueueName = 'queue1'
var storageAccount2QueueName = 'queue2'
var minimumElasticSize = ((environment == 'prod') ? 2 : 1)

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: uamiName
  location: location
}

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appInsights-${suffix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'logic-app-subnet'
        properties: {
          addressPrefixes: [
            cidrSubnet(addressPrefix, 24, 0)
          ]
          delegations: [
            {
              name: 'logic-app-delegation'
              type: 'Microsoft.Web/serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
        }
      }
    ]
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}

resource kvReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('kvReaderRoleAssignment', keyVaultSecretsUserRoleDefinitionId)
  scope: keyVault
  properties: {
    principalId: uami.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleDefinitionId)
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  kind: 'windows'
  properties: {
    targetWorkerCount: minimumElasticSize
    maximumElasticWorkerCount: 20
    elasticScaleEnabled: true
    isSpot: false
    zoneRedundant: false
  }
}

module storageAccount1 'modules/storageAccount.bicep' = {
  name: 'storage-account-1-module'
  params: {
    location: location
    storageAccountName: storageAccount1Name
    storageAccountQueueName: storageAccount1QueueName
    containerName: 'mycontainer1'
  }
}

module storageAccount2 'modules/storageAccount.bicep' = {
  name: 'storage-account-2-module'
  params: {
    location: location
    storageAccountName: storageAccount2Name
    storageAccountQueueName: storageAccount2QueueName
    containerName: 'mycontainer2'
  }
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-02-15-preview' = {
  name: cosmosAccountName
  kind: 'GlobalDocumentDB'
  location: location
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosDbAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/myPartitionKey'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
          {
            path: '/_etag/?'
          }
        ]
        compositeIndexes: [
          [
            {
              path: '/name'
              order: 'ascending'
            }
            {
              path: '/age'
              order: 'descending'
            }
          ]
        ]
        spatialIndexes: [
          {
            path: '/path/to/geojson/property/?'
            types: [
              'Point'
              'Polygon'
              'MultiPolygon'
              'LineString'
            ]
          }
        ]
      }
      defaultTtl: 86400
      uniqueKeyPolicy: {
        uniqueKeys: [
          {
            paths: [
              '/phoneNumber'
            ]
          }
        ]
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

output vnetName string = vnet.name
output subnetName string = vnet.properties.subnets[0].name
output keyVaultName string = keyVault.name
output appServicePlanName string = appServicePlan.name
output cosmosAccountName string = cosmosDbAccount.name
output databaseName string = database.name
output containerName string = container.name
output uamiName string = uami.name
output storageAccount1Name string = storageAccount1.outputs.storageAccountName
output storageAccount2Name string = storageAccount2.outputs.storageAccountName
output storageAccount1QueueName string = storageAccount1.outputs.queueName
output storageAccount2QueueName string = storageAccount2.outputs.queueName
output aiName string = ai.name
