param location string
param prefix string

@allowed([
  'PerGB2018'
])
param sku string = 'PerGB2018'

var affix = uniqueString(resourceGroup().id)
var wksName = '${prefix}-wks-${affix}'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: wksName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: 30
  }
}

output workspaceId string = azureMonitorWorkspace.id
