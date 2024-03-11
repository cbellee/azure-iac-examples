param apimName string
param blueAppFqdn string
param greenAppFqdn string

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' existing = {
  name: apimName
}

resource colourApp 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'colourapp'
  properties: {
    displayName: 'colourapp'
    apiRevision: '1'
    subscriptionRequired: false
    path: 'colourapp'
    protocols: ['https']
  }
}

resource colourAppGet 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: colourApp
  name: '65ebc90ebb313969c6969f12'
  properties: {
    displayName: 'colourapp_GET'
    method: 'GET'
    urlTemplate: '/*'
    templateParameters: []
    responses: []
  }
}

resource colourAppPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: colourApp
  name: 'policy'
  properties: {
    value: loadTextContent('../policies/apim-policy-template.xml')
    format: 'rawxml'
  }
}

resource colourAppBlue 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apim
  name: 'colourapp-blue'
  properties: {
    description: 'colourapp-blue'
    url: 'https://${blueAppFqdn}'
    protocol: 'http'
  }
}
