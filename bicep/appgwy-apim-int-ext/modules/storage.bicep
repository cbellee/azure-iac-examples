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

var resgpguid = substring(replace(guid(resourceGroup().id), '-', ''), 0, 6)
var storageAccountName_var = 'stor${resgpguid}'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName_var
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

resource storageAccountName_default_containerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccountName_var}/default/${containerName}'
  dependsOn: [
    storageAccountName
  ]
}

output storageAccountName string = storageAccountName_var
output storageAccountSasToken string = '?${listAccountSas(storageAccountName_var, '2018-07-01', accountSasProperties).accountSasToken}'
output storageContainerUri string = '${storageAccountName.properties.primaryEndpoints.blob}${containerName}'
