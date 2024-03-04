param location string
param suffix string
param principalId string

var name = 'kv-${suffix}'
var keyVaultAdministratorRoleId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource keyVaultAdministratorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: subscription()
  name: keyVaultAdministratorRoleId
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
  }
}

resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, name)
  properties: {
    principalId: principalId
    roleDefinitionId: keyVaultAdministratorRoleDefinition.id
    principalType: 'User'
  }
}

output name string = kv.name
output uri string = kv.properties.vaultUri
output id string = kv.id
