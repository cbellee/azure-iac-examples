param location string
param imageName string
param environment string
param appName string
param appPort string = '8080'
param tags object = {
  environment: 'dev'
  costcode: '1234567890'
}
param isExternalIngressEnabled bool = true
param containerAppEnvironmentName string
param acrName string

var userAssignedIdentityName = '${environment}-acr-${acrName}-umid'
var acrPullRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: userAssignedIdentityName
  tags: tags
}

resource existingAcr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: acrName
}

resource umidRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(existingAcr.id, resourceGroup().id, userAssignedIdentity.id)
  scope: existingAcr
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: acrPullRoleId
    principalType: 'ServicePrincipal'
    description: 'acrPull role assignment for ${environment} environment'
  }
}

resource app 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${environment}-${appName}'
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      registries: [
        {
          identity: userAssignedIdentity.id
          server: '${acrName}.azurecr.io'
        }
      ]
      ingress: {
        external: isExternalIngressEnabled
        targetPort: int(appPort)
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        transport: 'http'
      }
    }
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvironmentName)
    template: {
      containers: [
        {
          image: imageName
          name: appName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: [
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}

output appFqdn string = app.properties.configuration.ingress.fqdn
