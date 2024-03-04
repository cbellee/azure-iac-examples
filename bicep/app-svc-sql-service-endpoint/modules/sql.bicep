param sqlDBName string = 'SampleDB'
param location string
param subnetId string
param administratorLogin string
@secure()
param administratorLoginPassword string
param tags object

var suffix = uniqueString(resourceGroup().id)
var serverName = 'sql-${suffix}'

resource sqlServer 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServer
  name: sqlDBName
  tags: tags
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource virtualNetworkSetting 'Microsoft.Sql/servers/virtualNetworkRules@2021-08-01-preview' = {
  name: 'vnetSetting'
  parent: sqlServer
  properties: {
    ignoreMissingVnetServiceEndpoint: false
    virtualNetworkSubnetId: subnetId
  }
}

output sqlServerName string = serverName
