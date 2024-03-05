param location string
param imageName string
param environmentId string
param targetPort int
param prefix string
param colour string
param imageTag string
param umidId string
param acrName string

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-app-${suffix}'
var imageNameAndTag = '${imageName}:${imageTag}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${umidId}': {}
    }
  }
  properties: {
    workloadProfileName: null
    environmentId: environmentId
    configuration: {
      registries: [
        {
          identity: umidId
          server: acr.name
        }
      ]
      activeRevisionsMode: 'Multiple'
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
          image: imageNameAndTag
          name: name
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                port: 80
                path: '/healthz'
                httpHeaders: [
                  {
                    name: 'Custom-Header'
                    value: 'readiness probe'
                  }
                ]
              }
              initialDelaySeconds: 5
              successThreshold: 1
              periodSeconds: 20
              failureThreshold: 30
            }
            {
              type: 'Liveness'
              httpGet: {
                port: 80
                path: '/livez'
                httpHeaders: [
                  {
                    name: 'Custom-Header'
                    value: 'liveness probe'
                  }
                ]
              }
              initialDelaySeconds: 5
              successThreshold: 1
              periodSeconds: 20
              failureThreshold: 30
            }
            {
              type: 'Startup'
              httpGet: {
                port: 80
                path: '/startupz'
                httpHeaders: [
                  {
                    name: 'Custom-Header'
                    value: 'startup probe'
                  }
                ]
              }
              initialDelaySeconds: 5
              successThreshold: 1
              periodSeconds: 20
              failureThreshold: 30
            }
          ]
          env: [
            {
              name: 'VERSION'
              value: imageTag
            }
            {
              name: 'LOCATION'
              value: location
            }
            {
              name: 'COLOUR'
              value: colour
            }
          ]
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 6
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
