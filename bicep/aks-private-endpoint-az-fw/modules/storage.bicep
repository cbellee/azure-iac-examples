param storageSku string = 'Standard_LRS'
param storageKind string = 'StorageV2'
param containerName string
param sasTokenExpiry string
param accountSasProperties object = {
  signedServices: 'b'
  signedPermission: 'rl'
  signedExpiry: sasTokenExpiry
  signedResourceTypes: 'o'
}

var resgpguid = substring(replace(guid(resourceGroup().id), '-', ''), 0, 4)
var storageAccountName = 'stor${resgpguid}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2018-07-01' = {
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

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-07-01' = {
  name: '${storageAccountName}/default/${containerName}'
  dependsOn: [
    storageAccount
  ]
}

output storageAccountName string = storageAccountName
output storageAccountSasToken string = '?${listAccountSas(storageAccountName, '2018-07-01', accountSasProperties).accountSasToken}'
output storageContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}containerName}'
output containerName string = containerName
