@secure()
param administratorLoginPassword string
param administratorLogin string
param location string
param suffix string
param skuCapacity int = 1
param skuFamily string = 'Gen5'
param skuName string = 'B_Gen5_1'
param skuSizeMB int = 5120
param skuTier string = 'Basic'
param version string = '8.0'
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param tags object = {}
param storageAutoGrow string = 'Disabled'

var serverName = 'mysql-server-${suffix}'

resource serverName_resource 'Microsoft.DBForMySQL/servers@2017-12-01-preview' = {
  location: location
  tags: tags
  name: serverName
  properties: {
    createMode: 'Default'
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
      storageAutogrow: storageAutoGrow
    }
  }
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: string(skuSizeMB)
    family: skuFamily
  }
}
