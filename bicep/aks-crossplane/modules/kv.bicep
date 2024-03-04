param location string
param tags object
param prefix string

var suffix = uniqueString(resourceGroup().id)
var kvName = '${prefix}-kv-${suffix}'

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: kvName
  tags: tags
  location: location
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}

output name string = kv.name
output id string = kv.id
