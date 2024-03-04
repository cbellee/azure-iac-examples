param apimName string
param oApiSpecYaml string
param apiPoicyXml string
param apiName string
param backendUrl string

resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' existing = {
  name: apimName
}

// Import Open Api Definitions
module openApiDefinition '../infra/modules/api.bicep' = {
  name: 'module-${apiName}-api'
  params: {
    apimName: apim.name
    backendUrl: backendUrl
    apiName: '${apiName}-api'
    apiPath: 'api/${apiName}'
    displayName: '${apiName} API'
    isSubscriptionRequired: false
    openApiYaml: oApiSpecYaml
    xmlPolicy: apiPoicyXml
  }
}
