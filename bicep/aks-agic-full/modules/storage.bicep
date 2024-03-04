param name string
param location string
param sku string {
  default: 'Standard_LRS'
}
param kind string {
  default: 'Storagev2'
}

resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  kind: kind
}

output blobStorageAccount object = blobStorageAccount