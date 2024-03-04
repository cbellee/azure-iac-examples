param prefix string
param webAppName string = concat(prefix, uniqueString(resourceGroup().id))
param sku string = 'P1V2'
param containerImageName string
param location string = resourceGroup().location
param containerPort string
param subnetId string

var appServicePlanName = toLower('${prefix}-asp')
var webSiteName = toLower('${prefix}-app')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: concat('DOCKER|', containerImageName)
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: containerPort
        }
      ]
      ipSecurityRestrictions: [
        {
          vnetSubnetResourceId: subnetId
          action: 'Allow'
          tag: 'Default'
          priority: 1000
          name: 'ApplicationGatewaySubnet'
          description: 'Isolate traffic to subnet containing Azure Application Gateway'
        }
      ]
    }
  }
}

output webAppHostName string = appService.properties.hostNames[0]
