param location string
param imageName string
param environmentId string
param targetPort int = 80
param prefix string
param colour string
param imageTag string

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-app-${suffix}'
var imageNameAndTag = '${imageName}:${imageTag}'

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    workloadProfileName: null
    environmentId: environmentId
    configuration: {
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
        maxReplicas: 10
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
