param tenantId string
param location string
param name string 

var suffix = uniqueString(resourceGroup().id) 
var kvName = '${name}-${suffix}'

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: kvName
  location: location
  tags: {
    displayName: kvName
  }
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    createMode: 'default'
    tenantId: tenantId
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVault object = keyVault
