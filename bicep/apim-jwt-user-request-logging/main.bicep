param apiPath string = '/jwt-test'
param location string =  'australiaeast'
param publisherEmail string = 'cbellee@microsoft.com'
param publisherName string = 'kaini industries'
param suffix string = uniqueString(resourceGroup().id)
param apimName string = 'apim-${suffix}'
param aiName string = 'ai-${suffix}'
param lawName string = 'law-${suffix}' 

var apiPolicy = loadTextContent('./api-policy.xml')

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: lawName
  location: location
}

resource apim 'Microsoft.ApiManagement/service@2022-09-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Consumption'
    capacity: 0
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    notificationSenderEmail: 'apimgmt-noreply@mail.windowsazure.com'
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: '${apimName}.azure-api.net'
        negotiateClientCertificate: false
        defaultSslBinding: true
        certificateSource: 'BuiltIn'
      }
    ]
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'true'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'true'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'true'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'true'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'false'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'true'
    }
    virtualNetworkType: 'None'
    enableClientCertificate: false
    disableGateway: false
    natGatewayState: 'Disabled'
    apiVersionConstraint: {}
    publicNetworkAccess: 'Enabled'
  }
}

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: aiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    RetentionInDays: 90
    WorkspaceResourceId: law.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource api 'Microsoft.ApiManagement/service/apis@2022-09-01-preview' = {
  parent: apim
  name: 'jwt-test'
  properties: {
    displayName: 'jwt-test'
    apiRevision: '1'
    subscriptionRequired: false
    protocols: [
      'https'
    ]
    authenticationSettings: {
      oAuth2AuthenticationSettings: []
      openidAuthenticationSettings: []
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
    path: apiPath
  }
}

resource api_product_api 'Microsoft.ApiManagement/service/products/apis@2022-09-01-preview' = {
  parent: api_product
  name: 'jwt-test'
}

resource api_get_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2022-09-01-preview' = {
  parent: api_get
  name: 'policy'
  properties: {
    value: apiPolicy
    format: 'rawxml'
  }
}

resource api_product 'Microsoft.ApiManagement/service/products@2022-09-01-preview' = {
  parent: apim
  name: 'jwt-test-product'
  properties: {
    displayName: 'jwt-test-product'
    description: 'jwt-test-product'
    subscriptionRequired: false
    state: 'published'
  }
}

resource api_get 'Microsoft.ApiManagement/service/apis/operations@2022-09-01-preview' = {
  parent: api
  name: 'test-get'
  properties: {
    displayName: 'test-get'
    method: 'GET'
    urlTemplate: '/'
    templateParameters: []
    responses: [
      {
        statusCode: 200
        representations: [
          {
            contentType: 'application/json'
            examples: {
              default: {
                value: {}
              }
            }
          }
        ]
        headers: []
      }
    ]
  }
}

resource apimName_applicationinsights 'Microsoft.ApiManagement/service/diagnostics@2022-09-01-preview' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'Legacy'
    logClientIp: true
    loggerId: apim_logger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: '*'
              mode: 'Hide'
            }
          ]
        }
      }
    }
    backend: {
      request: {
        dataMasking: {
          queryParams: [
            {
              value: '*'
              mode: 'Hide'
            }
          ]
        }
      }
    }
  }
}

resource apim_diagnostics 'Microsoft.ApiManagement/service/diagnostics/loggers@2018-01-01' = {
  parent: apimName_applicationinsights
  name: '${apimName}-ai'
}

resource apim_logger 'Microsoft.ApiManagement/service/loggers@2022-09-01-preview' = {
  parent: apim
  name: '${apimName}-ai'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey: appInsights.properties.InstrumentationKey
    }
    isBuffered: true
    resourceId: appInsights.id
  }
}

output apiUrl string = '${apim.properties.gatewayUrl}/${api.properties.displayName}'
