param location string
param secretName string
param umidName string

@secure()
param secretValue string

var suffix = uniqueString(resourceGroup().id)
var kvName = 'kv-${suffix}'
var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: umidName
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    tenantId: tenant().tenantId
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: secretName
  parent: kv
  properties: {
    value: secretValue
  }
}

resource secretsOfficer 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('secretsOfficer', keyVaultSecretsUserRoleId)
  scope: kv
  properties: {
    principalId: umid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
  }
}

output name string = kv.name
output secretId string = secret.id
output secretName string = secret.name
output keyVaultUrl string = kv.properties.vaultUri
