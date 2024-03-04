param location string
param name string

@allowed([
  'PerGB2018'
])
param sku string = 'PerGB2018'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: 30
  }
}

output workspaceId string = azureMonitorWorkspace.id
