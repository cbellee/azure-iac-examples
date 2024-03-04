param objectId string
param keyVaultName string
param permissions object

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        objectId: objectId
        permissions: permissions
        tenantId: tenant().tenantId
      }
    ]
  }
}
