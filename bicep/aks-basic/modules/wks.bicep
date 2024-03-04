param location string
param suffix string
param tags object
param retentionInDays int = 30

@allowed([
  'PerGB2018'
])
param sku string = 'PerGB2018'

var workspaceName = 'wks-${suffix}'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  location: location
  name: workspaceName
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
  }
}

output workspaceId string = azureMonitorWorkspace.id
