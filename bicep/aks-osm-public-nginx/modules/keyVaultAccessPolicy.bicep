param keyVaultName string
param accessPolicies array

var tenantId = tenant().tenantId

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource accessPols 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
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
