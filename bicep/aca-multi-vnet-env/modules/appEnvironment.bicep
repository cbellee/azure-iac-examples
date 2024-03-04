param location string
param appEnvironmentName string
param isZoneRedundant bool = false
param isInternal bool = true
param subnetId string
param workspaceName string

var defaultDomainArr = split(appEnvironment.properties.defaultDomain, '.')
var managedResourceGroupName = 'MC_${defaultDomainArr[0]}-rg_${defaultDomainArr[0]}_${defaultDomainArr[1]}'

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource appEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: appEnvironmentName
  location: location
  properties: {
    vnetConfiguration: {
      internal: isInternal
      infrastructureSubnetId: subnetId
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
output managedResourceGroupName string = managedResourceGroupName
output domainName string = appEnvironment.properties.defaultDomain
output ipAddress string = appEnvironment.properties.staticIp
output firstDomainSegment string = split(appEnvironment.properties.defaultDomain, '.')[0]
