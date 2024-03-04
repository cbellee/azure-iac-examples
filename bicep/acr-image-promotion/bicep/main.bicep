param location string
param isZoneRedundant bool = false
param environments array = [
  'dev'
  'test'
  'prod'
]

param tags object = {
  environment: 'dev'
  costcode: '1234567890'
}

var suffix = uniqueString(resourceGroup().id)
var wksName = 'wks-${suffix}'
var altName = 'alt-${suffix}'

resource wks 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: wksName
  tags: tags
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource azLoadTest 'Microsoft.LoadTestService/loadTests@2022-12-01' = {
  name: altName
  location: location
  tags: tags 
}



resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = [for environment in environments: {
  name: 'acr${environment}${suffix}'
  tags: tags
  location: location
  sku: {
    name: 'Standard'
  }
}]

resource aca 'Microsoft.App/managedEnvironments@2022-06-01-preview' = [for environment in environments: {
  location: location
  name: 'aca-env-${environment}-${suffix}'
  tags: tags
  sku: {
    name: 'Consumption'
  }
  properties: {
    zoneRedundant: isZoneRedundant
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
  }
}]

output acaEnvironments array = [for (environment, i) in environments: {
  name: aca[i].name
  id: aca[i].id
  environment: environment
}]

output acrEnvironments array = [for (environment, i) in environments: {
  name: acr[i].name
  id: acr[i].id
  environment: environment
}]

output loadTestName string = azLoadTest.name
