param location string
param aiName string

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  kind: 'web'
  location: location
  name: aiName
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    RetentionInDays: 30
  }
}

output aiKey string = ai.properties.InstrumentationKey
