param location string = 'australiaeast'
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-queuereader'
var suffix = uniqueString(resourceGroup().id)
var workspaceName = 'wks-${suffix}'
var environmentName = 'env-${suffix}'
var appName = 'app-${suffix}'
var storageAccountName = 'stg${suffix}'
var storageQueueName = 'myqueue'
var queuStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${stor.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(stor.id, stor.apiVersion).keys[0].value};BlobEndpoint=https://${stor.name}.blob.core.windows.net/;FileEndpoint=https://${stor.name}.file.core.windows.net/;QueueEndpoint=https://${stor.name}.queue.core.windows.net/;TableEndpoint=https://${stor.name}.table.core.windows.net/'


resource stor 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource storageService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  name: 'default'
  parent: stor
}

resource storageQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01' = {
  name: storageQueueName
  parent: storageService
}

resource wks 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource env 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
  }
}

resource app 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: appName
  location: location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', environmentName)
    configuration: {
      activeRevisionsMode: 'single'
      secrets: [
        {
          name: 'queueconnection'
          value: queuStorageConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: appName
          env: [
            {
              name: 'QueueName'
              value: storageQueueName
            }
            {
              name: 'QueueConnectionString'
              secretRef: 'queueconnection'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'myqueuerule'
            azureQueue: {
              queueName: 'myqueue'
              queueLength: 100
              auth: [
                {
                  secretRef: 'queueconnection'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
}

// output appFqdn string = app.properties.configuration.ingress.fqdn
