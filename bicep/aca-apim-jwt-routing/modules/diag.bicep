param retentionDays int = 30
param workspaceId string

var name = 'diagmostics-setting'

resource symbolicname 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: name
  properties: {
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'string'
        categoryGroup: 'string'
        enabled: true
        retentionPolicy: {
          days: retentionDays
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'string'
        enabled: true
        retentionPolicy: {
          days: retentionDays
          enabled: true
        }
      }
    ]
    workspaceId: workspaceId
  }
}
