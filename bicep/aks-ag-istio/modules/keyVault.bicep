param location string
param umidName string
param userPrincipalId string

@secure()
param rootCertificateData string

var affix = uniqueString(resourceGroup().id)
var name = 'kv-${affix}'
var keyVaultAdministratorRoleId = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
var keyVaultSecretsOfficerRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: umidName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: true
    enableRbacAuthorization: true
    createMode: 'default'
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource rootCertSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'root-cert'
  properties: {
    value: rootCertificateData
    attributes: {
      enabled: true
    }
  }
}

resource keyVaultSecretsOfficerRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVault.name, 'keyVaultSecretsOfficerRole')
  properties: {
    principalId: umid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsOfficerRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource keyVaultAdminRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVault.name, 'keyVaultAdministratorRole')
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultAdministratorRoleId)
    principalType: 'User'
  }
}

output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output umidName string = umid.name
output rootCertificateSecretId string = rootCertSecret.properties.secretUri
