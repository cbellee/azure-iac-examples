param mySqlAdminUserName string = 'dbadmin'

@secure()
param mySqlAdminPassword string
param location string
param suffix string
param serverEdition string = 'GeneralPurpose'
param vCores int = 2
param storageSizeMB int = 10240
param haEnabled string = 'Enabled'
param availabilityZone string = ''
param version string = '8.0.21'
param subnetArmResourceId string
param tags object = {
  costcenter: '1234567890'
  environment: 'dev'
}
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param vmName string = 'Standard_D2ds_v4'

@description('Value should be either Enabled or Disabled')
param publicNetworkAccess string = 'Disabled'
param storageIops int = 100

var serverName = 'mysqlflex${suffix}'
var firewallRuleName = '${serverName}-fw-rules'

resource mySqlFlexServer 'Microsoft.DBforMySQL/flexibleServers@2020-07-01-privatepreview' = {
  location: location
  name: serverName
  properties: {
    version: version
    mySqlAdminUserName: mySqlAdminUserName
    mySqlAdminPassword: mySqlAdminPassword
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
    name: vmName
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

output mySqlServerName string = mySqlFlexServer.name
