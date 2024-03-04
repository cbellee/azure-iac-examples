param keyVaultUserObjectId string = 'default'
param keyVaultAdminObjectId string
param deployUserAccessPolicy bool = false
param tags object

var suffix = uniqueString(resourceGroup().id)
var name = 'kv-${suffix}'
var location = resourceGroup().location

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  
  name: name
  location: location
  tags: tags
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
    createMode: 'default'
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: keyVaultAdminObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'import'
          ]
          secrets: [
            'get'
            'list'
            'set'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'import'
            'update'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource RO_AccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = if (deployUserAccessPolicy) {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        permissions: {
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
        objectId: keyVaultUserObjectId
      }
    ]
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
