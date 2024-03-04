param location string
param subnetId string
param containerName string
//param acrName string
param tags object

@allowed([
  'S1'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param skuName string = 'S1'

var suffix = uniqueString(resourceGroup().id)
var serverFarmName = 'app-svc-${suffix}'
var siteName = 'my-app-${suffix}'
/* var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource existingAcr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}
 */
resource serverFarm 'Microsoft.Web/serverfarms@2020-12-01' = {
  kind: 'linux'
  tags: tags
  location: location
  name: serverFarmName
  sku: {
    name: skuName
    size: skuName
    family: skuName
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerName}'

      vnetRouteAllEnabled: true
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: true
      logsDirectorySizeLimit: 35
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource siteProperties 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  parent: webApp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnetId
    swiftSupported: true
  }
}

resource webAppAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webApp.name}/appsettings'
  properties: {
    'WEBSITE_DNS_SERVER': '168.63.129.16'
    //'WEBSITE_VNET_ROUTE_ALL': '1'
    //'WEBSITES_ENABLE_APP_SERVICE_STORAGE': false
    //'DOCKER_REGISTRY_SERVER_URL': dockerRegistryUrl
    //'DOCKER_REGISTRY_SERVER_USERNAME': acrUserName
    //'DOCKER_REGISTRY_SERVER_PASSWORD': acrPassword
    //'WEBSITE_PULL_IMAGE_OVER_VNET': true
  }
}

/* resource appServiceAcrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: existingAcr
  name: guid(existingAcr.id, webApp.id, acrPullRoleDefinitionId)
  properties: {
    principalId: webApp.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
} */

output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
