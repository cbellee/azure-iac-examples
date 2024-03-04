param location string
param name string
param aiKey string
param wksCustomerId string
param wksSharedKey string
param infrastructureSubnetId string
param runtimeSubnetId string
param tags object

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  location: location
  name: name
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
      runtimeSubnetId: runtimeSubnetId
      internal: false
    }
    daprAIInstrumentationKey: aiKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wksCustomerId
        sharedKey: wksSharedKey
      }
    }
  }
  tags: tags
}

output id string = containerAppEnvironment.id
output name string = containerAppEnvironment.name
