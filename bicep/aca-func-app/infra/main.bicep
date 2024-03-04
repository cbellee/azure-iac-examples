param location string
param acrName string
param imageName string
param funcName string
param funcPort string
param isExternalIngressEnabled bool = true

@secure()
param acrTokenPassword string
param acrTokenName string

param tags object = {
  environment: 'dev'
  costcode: '1234567890'
}

var affix = uniqueString(resourceGroup().id)
var containerAppEnvName = 'capp-env-${affix}'
var acrLoginServer = '${acrName}.azurecr.io'
// var acrAdminPassword = listCredentials(acr.id, '2021-12-01-preview').passwords[0].value

var workspaceName = 'wks-${affix}'
var secrets = [
  /* {
    name: 'registry-password'
    value: acrAdminPassword
  } */
  {
    name: 'acr-token-password'
    value: acrTokenPassword
  }
]

/* resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: acrName
} */

module wksModule 'modules/wks.bicep' = {
  name: 'module-wks'
  params: {
    location: location
    name: workspaceName
    tags: tags
  }
}

module containerAppEnvModule './modules/cappenv.bicep' = {
  name: 'modules-cappenv'
  params: {
    name: containerAppEnvName
    location: location
    tags: tags
    wksSharedKey: wksModule.outputs.workspaceSharedKey
    wksCustomerId: wksModule.outputs.workspaceCustomerId
  }
}

resource todoFuncApi 'Microsoft.App/containerApps@2022-03-01' = {
  name: funcName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      secrets: secrets
      registries: [
        {
          server: acrLoginServer
          username: acrTokenName
          passwordSecretRef: 'acr-token-password'
        }
      ]
      ingress: {
        external: isExternalIngressEnabled
        targetPort: int(funcPort)
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        transport: 'http'
      }
    }
    managedEnvironmentId: containerAppEnvModule.outputs.id
    template: {
      containers: [
        {
          image: imageName
          name: funcName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'FUNCTIONS_CUSTOMHANDLER_PORT'
              value: funcPort
            }
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
