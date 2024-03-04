param location string
param prefix string
param isMTLSEnabled bool
param workspaceName string
param isZoneRedundant bool = true

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-env-${suffix}'

var defaultDomainArr = split(appEnvironment.properties.defaultDomain, '.')
var managedResourceGroupName = 'MC_${defaultDomainArr[0]}-rg_${defaultDomainArr[0]}_${defaultDomainArr[1]}'

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource appEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  properties: {
    workloadProfiles: null
    peerAuthentication: {
      mtls: {
        enabled: isMTLSEnabled
      }
    }
    vnetConfiguration: {
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
    zoneRedundant: isZoneRedundant
  }
}

output name string = appEnvironment.name
output id string = appEnvironment.id
output staticIp string = appEnvironment.properties.staticIp
output defaultDomain string = appEnvironment.properties.defaultDomain
output managedResourceGroupName string = managedResourceGroupName
output ipAddress string = appEnvironment.properties.staticIp
