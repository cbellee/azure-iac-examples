param location string
param secretValue string

var suffix = uniqueString(resourceGroup().id)
var storageAccountName = 'stor${suffix}'
var keyVaultName = 'kv-${suffix}'
var userMIDName = 'script-resource-mid-${suffix}'

resource user_assigned_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userMIDName
  location: location
}

resource key_Vault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  location: location
  name: keyVaultName
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: user_assigned_identity.properties.principalId
        permissions: {
          secrets: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

resource storage_account 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  name: storageAccountName
  properties: {
    accessTier: 'Hot'
  }
}

module scriptDeployment 'script-deployment.bicep' = {
  name: 'module-script-deployment'
  params: {
    location: location
    storageAccountName: storage_account.name 
    keyVaultName: key_Vault.name
    identity: user_assigned_identity.id
    secret: secretValue
  }
}

output scriptOutput string = scriptDeployment.outputs.scriptOutput
