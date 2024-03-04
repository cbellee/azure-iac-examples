param name string

@allowed([
  'australiaeast'
  'australiacentral'
  'australiacentral2'
  'australiasoutheast'
])
param location string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param sku string = 'Standard_LRS'

@allowed([
  'StorageV2'
  'Storage'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  kind: kind
}

output id string = storage.id
output name string = storage.name
