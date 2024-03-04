param keyVaultName string
param principalId string

var keyVaultReaderRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource keyVaultRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVaultReaderRoleDefinitionId)
  scope: keyVault
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultReaderRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}
