param location string

var suffix = uniqueString(resourceGroup().id)
var name = 'wks-${suffix}'

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output name string = wks.name
output id string = wks.id
output customerId string = wks.properties.customerId
output apiVersion string = wks.apiVersion
output sharedKey string = wks.listKeys().primarySharedKey
