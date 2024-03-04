param location string
param keyVaultName string
param adminUserObjectId string
param subnetId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  location: location
  name: keyVaultName
  properties: {
    enableSoftDelete: true
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: subnetId
        }
      ]
    }
    accessPolicies: [
      {
        objectId: adminUserObjectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
        }
      }
    ]
  }
}

output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
