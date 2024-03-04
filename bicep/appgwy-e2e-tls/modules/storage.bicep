param storageSku string = 'Standard_LRS'
param storageKind string = 'StorageV2'
param containerName string

var suffix = uniqueString(resourceGroup().id)
var storageAccountName = 'stor${suffix}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  sku: {
    name: storageSku
  }
  kind: storageKind
  location: resourceGroup().location
  properties: {
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
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  dependsOn: []
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName}/default/${containerName}'
  dependsOn: [
    storageAccount
  ]
}

output storageAccountName string = storageAccount.name
output containerName string = containerName
output storageContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'

