param suffix string = uniqueString(resourceGroup().id)
param subnetId string
param workspaceName string
param location string
param environmentName string = 'aca-environment-${suffix}'
param workloadProfiles array

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
}

resource aca_environment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: environmentName
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: subnetId
      internal: true
    }
    appLogsConfiguration: {
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: listKeys(workspace.id, workspace.apiVersion).primarySharedKey
      }
    }
    workloadProfiles: workloadProfiles
    zoneRedundant: false
  }
}

output id string = aca_environment.id
output defaultDomain string = aca_environment.properties.defaultDomain
output ipAddress string = aca_environment.properties.staticIp
