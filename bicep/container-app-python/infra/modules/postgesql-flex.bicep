param name string
param location string
param adminLoginName string
param adminPassword string
param subnetId string
param dnsZoneId string
param storageSizeGB int
param postGreSQLDbName string

var affix = substring(uniqueString(resourceGroup().id), 0, 6)
var serverName = '${name}-server-${affix}'

resource postGreSQLServer 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  location: location
  name: serverName
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: adminLoginName
    administratorLoginPassword: adminPassword
    createMode: 'Create'
    network: {
      delegatedSubnetResourceId: subnetId
      privateDnsZoneArmResourceId: dnsZoneId
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
    version: '13'
  }
}

resource postGreSQLDb 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2021-06-01' = {
  name: postGreSQLDbName
  parent: postGreSQLServer
}

output postGreSQLServerName string = postGreSQLServer.name
output postGreSQLDbName string = postGreSQLDb.name
output postGreSQLCxn string = 'host=${postGreSQLServer.properties.fullyQualifiedDomainName} port=5432 dbname=${postGreSQLDb.name} user=${postGreSQLServer.properties.administratorLogin} password=${adminPassword} sslmode=require'
