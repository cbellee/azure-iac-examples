param location string
param name string
param tags object
param storageAccountName string
param isSynapseManagedVnetEnabled bool
param isSynapseDEPEnabled bool
param isPublicNetworkAccessEnabled bool = true
param isGrantSqlControlToManagedIdentityEnabled bool = true
param administratorUsername string
param synapseSqlAdminGroupName string
param synapseSqlAdminGroupObjectID string

@secure()
param administratorPassword string

var affix = uniqueString(resourceGroup().id)
var synapseName = '${name}${affix}'
var managedResourceGroupName = 'syn-${affix}-rg'
var fileSystemName = 'files'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource synapse 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: synapseName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${storageAccountName}.dfs.${environment().suffixes.storage}' 
      filesystem: fileSystemName
      resourceId: storage.id
      createManagedPrivateEndpoint: isSynapseManagedVnetEnabled ? true : false
    }
    managedResourceGroupName: managedResourceGroupName
    managedVirtualNetwork: isSynapseManagedVnetEnabled ? 'default' : null
    managedVirtualNetworkSettings: isSynapseManagedVnetEnabled ? {
      allowedAadTenantIdsForLinking: []
      linkedAccessCheckOnTargetResource: true
      preventDataExfiltration: isSynapseDEPEnabled
    } : null
    publicNetworkAccess: isPublicNetworkAccessEnabled ? 'Enabled' : 'Disabled'
    sqlAdministratorLogin: administratorUsername
    sqlAdministratorLoginPassword: administratorPassword
  }
}

resource synapseManagedIdentitySqlControlSettings 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-06-01' = {
  parent: synapse
  name: 'default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: isGrantSqlControlToManagedIdentityEnabled ? 'Enabled' : 'Disabled'
    }
  }
}

resource synapseAadAdministrators 'Microsoft.Synapse/workspaces/administrators@2021-03-01' = if (!empty(synapseSqlAdminGroupName) && !empty(synapseSqlAdminGroupObjectID)) {
  parent: synapse
  name: 'activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: synapseSqlAdminGroupName
    sid: synapseSqlAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}
