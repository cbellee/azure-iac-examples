param location string
param isRbacEnabled bool = true
param prefix string
param principalId string

var affix = uniqueString(resourceGroup().id)
var t = replace(prefix, '-', '')
var kvName = '${t}${affix}'
var keyVaultAdministrator = '00482a5a-887f-4fb3-b363-3b7fe8e74483'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
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

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, kvName, keyVaultAdministrator)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultAdministrator)
  }
}

output id string = kv.id
output uri string = kv.properties.vaultUri
output name string = kv.name
