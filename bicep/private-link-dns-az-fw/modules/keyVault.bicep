param prefix string
//param userAssignedManagedIdentity object
//param certificateData string
param adminUserObjectId string

var keyVaultName = '${prefix}-kv'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  location: resourceGroup().location
  name: keyVaultName
  properties: {
    enableSoftDelete: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
/*       {
        objectId: userAssignedManagedIdentity.properties.principalId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'set'
            'list'
            'get'
          ]
        }
      } */
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

/* resource secret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyVault.name}/${prefix}-ssl-cert'
  properties: {
    value: certificateData
    attributes: {
      enabled: true
    }
  }
} */

output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
//output secretUri string = secret.properties.secretUriWithVersion
//output secretId string = secret.id
