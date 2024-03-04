param apimName string
param apiName string
param functionUri string

resource api 'Microsoft.ApiManagement/service/apis@2021-01-01-preview' = {
  name: '${apimName}/${apiName}'
  properties: {
    displayName: apimName
    apiRevision: '1'
    description: 'Example Todo API Definition'
    subscriptionRequired: false
    serviceUrl: functionUri
    protocols: [
      'https'
    ]
    isCurrent: true
    path: 'external'
  }
}

 output apiName string = apiName
 output apiId string = api.id
