param storageSku string = 'Standard_LRS'
param storageKind string = 'StorageV2'
param containerName string = 'scripts'
param sasTokenExpiry string
param location string
param accountSasProperties object = {
  signedServices: 'b'
  signedPermission: 'rwl'
  signedExpiry: sasTokenExpiry
  signedResourceTypes: 'o'
}

var resgpguid = substring(replace(guid(resourceGroup().id), '-', ''), 0, 6)
var storageAccountName = 'stor${resgpguid}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  sku: {
    name: storageSku
  }
  kind: storageKind
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowSharedKeyAccess: true
    allowBlobPublicAccess: true
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

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName}/default/${containerName}'
  properties: {
    publicAccess: 'Container'
  }
  dependsOn: [
    storageAccount
  ]
}

output storageAccountName string = storageAccountName
output storageContainerName string = containerName
output storageAccountSasToken string = '?${listAccountSas(storageAccountName, '2018-07-01', accountSasProperties).accountSasToken}'
output storageContainerUri string = '${storageAccount.properties.primaryEndpoints.blob}${containerName}'
