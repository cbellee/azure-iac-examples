param location string
param accessPolicies array

var affix = uniqueString(resourceGroup().id)
var kvName = 'kv-${affix}'
var tenantId = tenant().tenantId

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  location: location
  name: kvName
  properties: {
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
  }
}

resource accessPol 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: 'add'
  parent: kv
  properties: {
    accessPolicies: [for accessPolicy in accessPolicies: {
      tenantId: tenantId
      objectId: accessPolicy.objectId
      permissions: {
        keys: accessPolicy.permissions.keys
        secrets: accessPolicy.permissions.secrets
        certificates: accessPolicy.permissions.certificates
      }
    }]
  }
}
