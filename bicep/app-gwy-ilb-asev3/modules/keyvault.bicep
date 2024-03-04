param location string = resourceGroup().location
param prefix string
param principalId string
param appGatewayManagedIdentityId string

var keyVaultName = '${prefix}-kv'
var keyVaultAdministratorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
var keyVaultSecretsUserRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: keyVaultName
  }
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    createMode: 'default'
    tenantId: tenant().tenantId
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, keyVaultName, 'keyVaultContributor')
  scope: keyVault
  properties: {
    principalId: principalId
    roleDefinitionId: keyVaultAdministratorRoleId
  }
}

resource appGatewayRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, keyVaultName, 'keyVaultReader')
  scope: keyVault
  properties: {
    principalId: appGatewayManagedIdentityId
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVault object = keyVault
