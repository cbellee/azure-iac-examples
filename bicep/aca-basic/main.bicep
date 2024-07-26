param location string
param acrName string
param containerappName string = 'envvars'
param containerImageName string = 'envvars'
param containerImageTag string = 'latest'
param prefix string
param port int = 8080

var containerAppEnvName = '${prefix}-aca'
var uamiName = '${prefix}-acr-pull-umid'
var wksName = '${prefix}-wks'
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: acrPullRoleId
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
        targetPort: port
        external: true
      }

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
        }
      ]
    }
  }
  dependsOn: [
    acrRoleAssignment
  ]
}
