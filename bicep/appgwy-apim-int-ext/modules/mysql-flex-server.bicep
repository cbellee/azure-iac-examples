param administratorLogin string = 'dbadmin'

@secure()
param administratorLoginPassword string
param location string
param suffix string
param serverEdition string = 'GeneralPurpose'
param vCores int = 2
param storageSizeMB int = 10240
param haEnabled string = 'Enabled'
param availabilityZone string = ''
param version string = '8.0.21'
param subnetArmResourceId string
param tags object
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param vmSkuName string = 'Standard_D2ds_v4'
param mySqlDatabaseName string = 'todolist'

@description('Value should be either Enabled or Disabled')
param publicNetworkAccess string = 'Disabled'
param storageIops int = 100

var serverName = 'mysql-flex-server-${suffix}'
var firewallRuleName = '${serverName}-fw-rules'

resource mySqlFlexServer 'Microsoft.DBforMySQL/flexibleServers@2020-07-01-privatepreview' = {
  location: location
  name: serverName
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: publicNetworkAccess
    DelegatedSubnetArguments: {
      subnetArmResourceId: subnetArmResourceId
    }
    haEnabled: haEnabled
    storageProfile: {
      storageMB: storageSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
      storageIops: storageIops
    }
    availabilityZone: availabilityZone
  }
  sku: {
    name: vmSkuName
    tier: serverEdition
    capacity: vCores
  }
  tags: tags
}

resource firewallRules 'Microsoft.DBForMySql/flexibleServers/firewallRules@2020-07-01-preview' = {
  name: firewallRuleName
  parent: mySqlFlexServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mySqlDatabase 'Microsoft.DBForMySql/flexibleServers/databases@2020-07-01-preview' = {
  name: mySqlDatabaseName
  parent: mySqlFlexServer
}

output mySqlServerName string = mySqlFlexServer.name
output mySqlDatabaseName string  = mySqlDatabase.name
