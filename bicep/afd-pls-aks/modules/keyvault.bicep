param prefix string
param location string
param isRbacEnabled bool = true

var name = '${prefix}-akv'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    createMode: 'default'
    enableRbacAuthorization: isRbacEnabled
    enableSoftDelete: true
  }
}

output id string = kv.id
output uri string = kv.properties.vaultUri
output name string = kv.name
