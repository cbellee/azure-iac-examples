param location string = resourceGroup().location
param tags object = {}
param administratorUsername string
param name string

@secure()
param administratorPassword string

param synapseSqlAdminGroupName string
param synapseSqlAdminGroupObjectID string

var affix = uniqueString(resourceGroup().id, name)
var storageAccountName = 'stor${affix}'
var synapseName = 'syn${affix}'
// var existingResourceIdInAnotherSubscription = resourceId('345345-23452345-345345-3453', 'my-rg', 'Microsoft.Synapse/workspaces', 'synapseName')

module storage './modules/storage.bicep' = {
  name: 'storage-module'
  params: {
    location: location
    name: storageAccountName
  }
}

module synapse 'modules/synapse.bicep' = {
  name: 'synapse-module'
  params: {
    name: synapseName
    location: location
    tags: tags
    administratorPassword: administratorPassword
    administratorUsername: administratorUsername
    storageAccountName: storageAccountName
    isSynapseDEPEnabled: true
    isSynapseManagedVnetEnabled: true
    synapseSqlAdminGroupName: synapseSqlAdminGroupName
    synapseSqlAdminGroupObjectID: synapseSqlAdminGroupObjectID
  }
}
