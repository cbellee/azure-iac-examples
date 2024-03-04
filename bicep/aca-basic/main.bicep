param location string
param acrName string
param containerappName string = 'myapp'
param containerImageName string = 'busybox'
param containerImageTag string = 'latest'
param prefix string

@secure()
param secretValue string

var kvName = '${prefix}-kv'
var containerAppEnvName = '${prefix}-aca'
var uamiName = '${prefix}-acr-pull-umid'
var secretName = 'mysecret'
var wksName = '${prefix}-wks'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: acrPullRoleId
}

resource kvSecretsuserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: kvSecretsUserRoleId
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: wksName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
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

resource acr 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: acrName
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-02-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }

    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: secretName
  properties: {
    value: secretValue
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedManagedIdentity.id, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: kvSecretsuserRole.id
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedManagedIdentity.id, acr.id)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-02-preview' = {
  name: containerappName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      secrets: [
        {
          name: secretName
          keyVaultUrl: secret.properties.secretUri
          identity: userAssignedManagedIdentity.id
        }
      ]
      registries: [
        {
          identity: userAssignedManagedIdentity.id
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${acrName}.azurecr.io/${containerImageName}:${containerImageTag}'
          name: containerImageName
          env: [
            {
              name: 'OPEN_AI_CONNECTION_API_KEY'
              secretRef: secretName
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    kvRoleAssignment
    acrRoleAssignment
  ]
}
