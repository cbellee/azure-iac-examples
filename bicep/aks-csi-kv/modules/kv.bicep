param tenantId string
param location string
param name string 
param secretName string

@secure()
param secretValue string

var suffix = uniqueString(resourceGroup().id) 
var kvName = '${name}-${suffix}'

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: kvName
  location: location
  tags: {
    displayName: kvName
  }
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    createMode: 'default'
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: keyVault
  name: secretName
  properties: {
    value: secretValue
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVault object = keyVault
