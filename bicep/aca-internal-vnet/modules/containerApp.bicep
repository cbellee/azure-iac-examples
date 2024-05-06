param location string
param appName string
param imageName string
param environmentId string
param targetPort int = 80
param umidName string
param acrName string
param colour string

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: umidName
}

resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: appName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umid.id}': {}
    }
  }
  properties: {
    workloadProfileName: null
    environmentId: environmentId
    configuration: {
      registries: [
        {
          identity: umid.id
          server: '${acrName}.azurecr.io'
        }
      ]
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: targetPort
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
        allowInsecure: false
      }
    }
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
            {
              name: 'COLOUR'
              value: colour
            }
            {
              name: 'VERSION'
              value: '1.0'
            }
            {
              name: 'LOCATION'
              value: location
            }
          ]
        }
      ]
      scale: {
        maxReplicas: 5
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
output name string = containerApp.name
