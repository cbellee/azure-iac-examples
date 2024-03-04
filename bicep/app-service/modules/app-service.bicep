param location string
param appName string

var appServiceSkuName = 'S1'
var appServicePlanName = 'asp-${uniqueString(resourceGroup().id)}'
var appServiceCapacity = 1

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSkuName
    capacity: appServiceCapacity
  }
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

output appServiceHostName string = appService.properties.defaultHostName
