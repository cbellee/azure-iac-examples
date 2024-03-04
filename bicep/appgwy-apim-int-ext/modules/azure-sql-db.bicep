param location string
param sqlDbName string
param sqlAdminUserName string
param sqlAdminUserPassword string
param subnetId string
param tags object
param suffix string
param dbSku string = 'Basic'

var sqlServerName = 'sql-server-${suffix}'

resource sqlServer 'Microsoft.Sql/servers@2021-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUserName
    administratorLoginPassword: sqlAdminUserPassword
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlServerVnetRules 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01-preview' = {
  parent: sqlServer
  name: 'firewall'
  properties: {
    virtualNetworkSubnetId: subnetId
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2021-11-01-preview' = {
  location: location
  name: sqlDbName
  parent: sqlServer
  sku: {
    name: dbSku
  }
  tags: tags
}

output sqlServerName string = sqlServer.name
output sqlServerFQDN string = sqlServer.properties.fullyQualifiedDomainName
output dbName string = sqlDb.name
