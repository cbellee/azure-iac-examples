param keyVaultName string
param objectId string

resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: keyVaultName
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        permissions: {
          certificates: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
          keys: [
            'get'
            'list'
          ]
        }
        objectId: objectId
        tenantId: subscription().tenantId
      }
    ]
  }
}
